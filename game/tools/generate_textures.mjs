// Dependency-free source generator for the four equirectangular paint textures.
// Run: node game/tools/generate_textures.mjs
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const width = 1024;
const height = 512;
const outDir = path.resolve('game/textures');
fs.mkdirSync(outDir, { recursive: true });
const palette = {
  cream: [244, 229, 206], red: [241, 45, 48], yellow: [255, 191, 57], blue: [23, 98, 193],
  violet: [101, 48, 178], lavender: [213, 147, 244], pink: [234, 102, 216],
  teal: [13, 159, 162], coral: [245, 104, 49], gold: [255, 203, 69], magenta: [218, 42, 100]
};
const fract = x => x - Math.floor(x);
const tau = Math.PI * 2;

function paint(design, u, v) {
  if (design === 0) {
    let c = palette.cream;
    if (Math.abs(v - 0.42 + 0.09 * Math.sin(u * tau * 2 + v * 5)) < 0.16) c = palette.yellow;
    if (Math.abs(v - 0.30 + 0.095 * Math.sign(Math.sin(u * tau * 4))) < 0.075) c = palette.red;
    if (v > 0.68 + 0.06 * Math.sin(u * tau * 2)) c = palette.blue;
    return c;
  }
  if (design === 1) {
    let c = palette.violet;
    if (Math.abs(Math.sin(u * tau * 2 + v * 8)) < 0.47) c = palette.lavender;
    if (Math.hypot(fract(u * 7) - 0.5, fract(v * 4) - 0.5) < 0.115) c = palette.cream;
    return c;
  }
  if (design === 2) {
    let c = palette.teal;
    if (Math.abs(v - 0.5 + 0.12 * Math.sin(u * tau * 2)) < 0.1) c = palette.cream;
    if (Math.hypot(fract(u * 8) - 0.5, fract(v * 4) - 0.5) < 0.12) c = palette.gold;
    return c;
  }
  let c = (Math.floor(u * 10) + Math.floor(v * 5)) % 2 === 0 ? palette.gold : palette.coral;
  if (Math.hypot(fract(u * 5) - 0.5, fract(v * 5) - 0.5) < 0.115) c = palette.magenta;
  return c;
}

const crcTable = Uint32Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let i = 0; i < 8; i++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc(buffer) {
  let value = 0xffffffff;
  for (const byte of buffer) value = crcTable[(value ^ byte) & 255] ^ (value >>> 8);
  return (value ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const tag = Buffer.from(type);
  const size = Buffer.alloc(4); size.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4); checksum.writeUInt32BE(crc(Buffer.concat([tag, data])));
  return Buffer.concat([size, tag, data, checksum]);
}
function png(rgba) {
  const rows = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    const row = y * (1 + width * 4);
    rows[row] = 0;
    rgba.copy(rows, row + 1, y * width * 4, (y + 1) * width * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(rows, { level: 9 })), chunk('IEND', Buffer.alloc(0))
  ]);
}

for (let design = 0; design < 4; design++) {
  const pixels = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const [r, g, b] = paint(design, (x + 0.5) / width, (y + 0.5) / height);
    const i = (y * width + x) * 4;
    pixels[i] = r; pixels[i + 1] = g; pixels[i + 2] = b; pixels[i + 3] = 255;
  }
  const name = `ball_${'abcd'[design]}.png`;
  fs.writeFileSync(path.join(outDir, name), png(pixels));
  console.log(name);
}
