#!/usr/bin/env node
// pillar bake --rows N --seed S --out data.png
//   Bakes the dithered column and a fresh ivy plant into the data texture Pillar.qml animates.
// pillar render --out img.png [--width 3840 --height 2160 --scale 3 --x -60 --y 0] [--state pillar.json | --no-pillar]
//   Paints the Altura ground (ink, top glow, grain), optionally with the column as grown right now.
// Column pieces and the ivy growth are ported from altura-software/apps/landing (pillar-canvas.ts, pillar-ivy.ts).
import { readFileSync, writeFileSync, renameSync } from 'node:fs'
import { deflateSync, crc32 } from 'node:zlib'

const W = 132
const CAP_H = 56
const TILE_H = 8
const BASE_H = 64

export const STEM = 1
export const VOID = 2
const LEAF = 3
const LEAF_TONES = 3
export const IVY_ALPHA = [0, 1.6, 0, 1.4, 2, 2.7]
export const IVY_COOL = 1.4
const HOT = 0.62
const TIME_UNIT = 32
const NEVER = 65535

const RATE = 34
const EASE_IN = 2
const VINES = 3
const BRANCH = 0.01
const DEPTH = 3
const WANDER = 0.7
const OVERLAP = 20
const STAGES = [
  ['#.#', '###', '.#.'],
  ['.#.#.', '#####', '#####', '.###.', '..#..'],
  ['.##.##.', '#######', '#######', '#######', '.#####.', '..###..', '...#...'],
]
const STAGE_AT = [
  [1, 3],
  [25, 60],
  [150, 300],
]

function piece(name, h) {
  const on = new Uint8Array(W * h)
  const svg = readFileSync(new URL(`./pillar-${name}.svg`, import.meta.url), 'utf8')
  for (const [, x, y, w] of svg.matchAll(/M(\d+) (\d+)h(\d+)/g)) {
    const at = +y * W + +x
    on.fill(1, at, at + +w)
  }
  return on
}

export function column(rows) {
  const capital = piece('capital', CAP_H)
  const shaft = piece('shaft', TILE_H)
  const base = piece('base', BASE_H)
  const on = new Uint8Array(W * rows)
  for (let y = 0; y < rows; y++) {
    const [src, at] =
      y < CAP_H ? [capital, y * W] : y >= rows - BASE_H ? [base, (y - (rows - BASE_H)) * W] : [shaft, ((y - CAP_H) % TILE_H) * W]
    on.set(src.subarray(at, at + W), y * W)
  }
  return on
}

function extents(on, rows) {
  const lo = new Int16Array(rows).fill(W)
  const hi = new Int16Array(rows).fill(-1)
  for (let y = 0; y < rows; y++)
    for (let x = 0; x < W; x++)
      if (on[y * W + x]) {
        if (x < lo[y]) lo[y] = x
        hi[y] = x
      }
  return { lo, hi }
}

const ageOf = (n) => (n / RATE + EASE_IN) ** 2 - EASE_IN ** 2

function mulberry(seed) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = Math.imul(a ^ (a >>> 15), a | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

// Events sorted by birth, in seconds of plant age. Vines grow in distance-from-their-end
// coordinates, so a column of another height regrows the same plant.
export function growIvy(seed, rows, extent) {
  const at = []
  const kind = []
  const born = []
  const limit = rows / 2 + OVERLAP

  const emit = (x, y, k, t) => {
    if (x < 0 || x >= W || y < 0 || y >= rows) return
    at.push(y * W + x)
    kind.push(k)
    born.push(t)
  }

  const leaf = (x, y, side, t, rand) => {
    const roll = rand()
    const top = roll < 0.3 ? 0 : roll < 0.8 ? 1 : 2
    const tone = LEAF + Math.floor(rand() * LEAF_TONES)
    const sideways = rand() < 0.4
    const place = (u, v) => (sideways ? [x + side * (v + 1), y + u] : [x + side * 2 + u, y + v + 1])
    for (let s = 0; s <= top; s++) {
      const shape = STAGES[s]
      const half = (shape[0].length - 1) / 2
      const start = t + STAGE_AT[s][0] + rand() * STAGE_AT[s][1]
      const cells = []
      const taken = new Set()
      for (let v = 0; v < shape.length; v++)
        for (let u = -half; u <= half; u++) {
          if (shape[v][u + half] !== '#') continue
          const [px, py] = place(u, v)
          cells.push([px, py, start + (v + Math.abs(u)) * 0.2])
          taken.add(py * W + px)
        }
      for (const [px, py, when] of cells) if (!taken.has((py + 1) * W + px + 1)) emit(px + 1, py + 1, VOID, when)
      for (const [px, py, when] of cells) emit(px, py, tone, when)
    }
  }

  for (const flip of [false, true]) {
    const toY = (d) => (flip ? rows - 1 - d : d)
    const root = mulberry(seed ^ (flip ? 0x9e3779b9 : 0))
    const [lo0, hi0] = extent(0, flip)
    const queue = []
    for (let v = 0; v < VINES; v++)
      queue.push({
        x: lo0 + (hi0 - lo0) * ((v + 0.25 + root() * 0.5) / VINES),
        d: 0,
        heading: Math.PI / 2,
        pull: 0.06,
        n: 0,
        life: Infinity,
        delay: v * 2 + root() * 3,
        depth: 0,
        seed: root() * 4294967296,
      })

    while (queue.length) {
      const tip = queue.pop()
      const rand = mulberry(tip.seed)
      let { x, d, heading, n } = tip
      let side = rand() < 0.5 ? -1 : 1
      let leafIn = 2 + rand() * 3
      for (let life = tip.life; life > 0 && d < limit; life--) {
        heading += (rand() - 0.5) * WANDER
        heading += (Math.PI / 2 - heading) * tip.pull
        let nx = x + Math.cos(heading)
        const nd = d + Math.sin(heading)
        if (nd < 0) break
        const [lo, hi] = extent(Math.round(nd), flip)
        if (nx < lo + 1 || nx > hi - 1) {
          heading = Math.PI - heading
          nx = Math.min(hi - 1, Math.max(lo + 1, nx))
        }
        x = nx
        d = nd
        n++
        const t = tip.delay + ageOf(n)
        const px = Math.round(x)
        const py = toY(Math.round(d))
        emit(px, py, STEM, t)
        if (--leafIn <= 0) {
          leaf(px, py, side, t, rand)
          side = -side
          leafIn = 5 + rand() * 7
        }
        if (tip.depth < DEPTH && rand() < BRANCH)
          queue.push({
            x,
            d,
            heading: heading + (rand() < 0.5 ? -1 : 1) * (0.6 + rand() * 0.7),
            pull: 0.02,
            n,
            life: (40 + rand() * 140) / (tip.depth + 1),
            delay: tip.delay,
            depth: tip.depth + 1,
            seed: rand() * 4294967296,
          })
      }
    }
  }

  const order = Array.from(born.keys()).sort((a, b) => born[a] - born[b] || a - b)
  return {
    at: Int32Array.from(order, (i) => at[i]),
    kind: Uint8Array.from(order, (i) => kind[i]),
    born: Float32Array.from(order, (i) => born[i]),
  }
}

export function plant(rows, seed) {
  const on = column(rows)
  const { lo, hi } = extents(on, rows)
  const extent = (d, flip) => {
    const y = flip ? rows - 1 - d : d
    return [lo[y], hi[y]]
  }
  return { on, lo, hi, ivy: growIvy(seed >>> 0, rows, extent) }
}

function png(w, h, channels, pixels, level) {
  const stride = w * channels
  const raw = Buffer.alloc((stride + 1) * h)
  for (let y = 0; y < h; y++) {
    raw[y * (stride + 1)] = 0
    raw.set(pixels.subarray(y * stride, (y + 1) * stride), y * (stride + 1) + 1)
  }
  const chunk = (type, data) => {
    const out = Buffer.alloc(12 + data.length)
    out.writeUInt32BE(data.length, 0)
    out.write(type, 4, 'ascii')
    data.copy(out, 8)
    out.writeUInt32BE(crc32(out.subarray(4, 8 + data.length)), 8 + data.length)
    return out
  }
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(w, 0)
  ihdr.writeUInt32BE(h, 4)
  ihdr[8] = 8
  ihdr[9] = channels === 4 ? 6 : 2
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level })),
    chunk('IEND', Buffer.alloc(0)),
  ])
}

function writeAtomic(path, data) {
  writeFileSync(path + '.tmp', data)
  renameSync(path + '.tmp', path)
}

// Three texels per column pixel: [kinds, flags], then the first and the last ivy birth as
// 16-bit times, so the shader can replay the plant at any age without the event list.
function bake(rows, seed) {
  const { on, lo, hi, ivy } = plant(rows, seed)
  const n = W * rows
  const first = new Uint8Array(n)
  const last = new Uint8Array(n)
  const bornFirst = new Uint16Array(n).fill(NEVER)
  const bornLast = new Uint16Array(n).fill(NEVER)
  for (let e = 0; e < ivy.at.length; e++) {
    const i = ivy.at[e]
    const t = Math.min(NEVER - 1, Math.round(ivy.born[e] * TIME_UNIT))
    if (!first[i]) {
      first[i] = ivy.kind[e]
      bornFirst[i] = t
    } else {
      last[i] = ivy.kind[e]
      bornLast[i] = t
    }
  }
  const px = new Uint8Array(n * 12)
  for (let i = 0; i < n; i++) {
    const y = Math.floor(i / W)
    const x = i % W
    const inside = x > lo[y] && x < hi[y] ? 2 : 0
    const o = i * 12
    px.set([first[i] + 8 * last[i], on[i] | inside, 0, 255], o)
    px.set([bornFirst[i] >> 8, bornFirst[i] & 255, 0, 255], o + 4)
    px.set([bornLast[i] >> 8, bornLast[i] & 255, 0, 255], o + 8)
  }
  const end = ivy.born.length ? ivy.born[ivy.born.length - 1] + IVY_COOL : 0
  return { image: png(W * 3, rows, 4, px, 6), end }
}

// The column's alpha per source pixel once materialized, with the plant `age` seconds old.
function snapshot(rows, seed, age, rest) {
  const { on, ivy } = plant(rows, seed)
  const alpha = new Float32Array(W * rows)
  for (let i = 0; i < alpha.length; i++) alpha[i] = on[i] ? rest : 0
  for (let e = 0; e < ivy.at.length && ivy.born[e] <= age; e++) {
    const k = ivy.kind[e]
    const base = rest * IVY_ALPHA[k]
    const heat = Math.max(0, 1 - (age - ivy.born[e]) / IVY_COOL)
    alpha[ivy.at[e]] = k === VOID ? 0 : base + (HOT - base) * heat * heat
  }
  return alpha
}

const hex = (s) => [0, 2, 4].map((i) => parseInt(s.replace('#', '').slice(i, i + 2), 16) / 255)

function hash(x, y) {
  let h = Math.imul(x + 1, 374761393) ^ Math.imul(y + 1, 668265263)
  h = Math.imul(h ^ (h >>> 13), 1274126177)
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296
}

function render({ width, height, scale, x0, y0, palette, pillar }) {
  const bg = hex(palette.bg)
  const ink = hex(palette.fg)
  const dark = palette.mode !== 'light'
  const glow = dark ? [1, 0.045] : [0, 0.035]
  const px = new Uint8Array(width * height * 3)
  const cx = width / 2
  const cy = -0.1 * height
  for (let y = 0; y < height; y++) {
    const gy = (y + 0.5 - cy) / (0.8 * height)
    const sy = Math.floor((y - y0) / scale)
    for (let x = 0; x < width; x++) {
      const gx = (x + 0.5 - cx) / (1.2 * width)
      const g = glow[1] * Math.max(0, 1 - Math.hypot(gx, gy) / 0.55)
      let a = 0
      if (pillar) {
        const sx = Math.floor((x - x0) / scale)
        if (sx >= 0 && sx < W && sy >= 0 && sy < pillar.rows) a = pillar.alpha[sy * W + sx]
      }
      const n = hash(x, y)
      const o = (y * width + x) * 3
      for (let c = 0; c < 3; c++) {
        let v = bg[c] + (glow[0] - bg[c]) * g
        const grain = v < 0.5 ? 2 * v * n : 1 - 2 * (1 - v) * (1 - n)
        v += (grain - v) * 0.05
        v += (ink[c] - v) * a
        px[o + c] = Math.max(0, Math.min(255, Math.floor(v * 255 + n)))
      }
    }
  }
  return png(width, height, 3, px, 1)
}

function args(argv) {
  const out = {}
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i].replace(/^--/, '')
    if (argv[i + 1] === undefined || argv[i + 1].startsWith('--')) out[key] = true
    else out[key] = argv[++i]
  }
  return out
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [command, ...rest] = process.argv.slice(2)
  const opt = args(rest)
  const here = new URL('..', import.meta.url).pathname
  if (command === 'bake') {
    const rows = Math.max(CAP_H + BASE_H, Math.floor(+opt.rows))
    const { image, end } = bake(rows, +opt.seed)
    writeAtomic(opt.out, image)
    process.stdout.write(JSON.stringify({ rows, end }) + '\n')
  } else if (command === 'render') {
    const palette = JSON.parse(readFileSync(opt.palette || `${here}generated/shell-colors.json`, 'utf8'))
    const width = +(opt.width || 3840)
    const height = +(opt.height || 2160)
    const scale = +(opt.scale || 3)
    let pillar = null
    if (!opt['no-pillar']) {
      let seed = 1
      let age = 1e6
      try {
        const state = JSON.parse(readFileSync(opt.state || `${here}generated/pillar.json`, 'utf8'))
        seed = state.seed
        age = state.planted ? (Date.now() - state.planted) / 1000 : 0
      } catch {}
      const rows = Math.ceil((height - +(opt.y || 0)) / scale)
      pillar = { rows, alpha: snapshot(rows, seed, age, palette.mode === 'light' ? 0.1 : 0.11) }
    }
    writeAtomic(opt.out, render({ width, height, scale, x0: +(opt.x ?? -60), y0: +(opt.y || 0), palette, pillar }))
  } else {
    process.stderr.write('usage: pillar bake|render [options]\n')
    process.exit(2)
  }
}
