const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");
const statusEl = document.getElementById("status");

const GRAVITY = 0.55;
const FRICTION = 0.82;
const MOVE_SPEED = 0.9;
const MAX_SPEED = 5;
const JUMP_FORCE = -11;

const keys = {};

const player = {
  x: 80,
  y: 0,
  width: 32,
  height: 48,
  vx: 0,
  vy: 0,
  onGround: false,
  color: "#ff6b6b",
};

const platforms = [
  { x: 0, y: 400, width: 800, height: 50 },
  { x: 180, y: 320, width: 120, height: 16 },
  { x: 420, y: 260, width: 140, height: 16 },
  { x: 620, y: 340, width: 100, height: 16 },
];

const blocks = [
  { x: 220, y: 0, size: 36, color: "#ffd93d", carried: false },
  { x: 470, y: 0, size: 36, color: "#6bcb77", carried: false },
  { x: 650, y: 0, size: 36, color: "#4d96ff", carried: false },
];

let carriedBlock = null;

function rectsOverlap(a, b) {
  return (
    a.x < b.x + b.width &&
    a.x + a.width > b.x &&
    a.y < b.y + b.height &&
    a.y + a.height > b.y
  );
}

function getPlayerRect() {
  return { x: player.x, y: player.y, width: player.width, height: player.height };
}

function getBlockRect(block) {
  return { x: block.x, y: block.y, width: block.size, height: block.size };
}

function placeBlocksOnPlatforms() {
  for (const block of blocks) {
    let bestPlatform = platforms[0];
    for (const platform of platforms) {
      if (
        block.x + block.size / 2 >= platform.x &&
        block.x + block.size / 2 <= platform.x + platform.width
      ) {
        bestPlatform = platform;
      }
    }
    block.y = bestPlatform.y - block.size;
  }
}

function resolvePlatformCollisions(entity, width, height) {
  entity.onGround = false;

  for (const platform of platforms) {
    if (!rectsOverlap(
      { x: entity.x, y: entity.y, width, height },
      platform
    )) {
      continue;
    }

    const overlapLeft = entity.x + width - platform.x;
    const overlapRight = platform.x + platform.width - entity.x;
    const overlapTop = entity.y + height - platform.y;
    const overlapBottom = platform.y + platform.height - entity.y;

    const minOverlap = Math.min(overlapLeft, overlapRight, overlapTop, overlapBottom);

    if (minOverlap === overlapTop && entity.vy >= 0) {
      entity.y = platform.y - height;
      entity.vy = 0;
      entity.onGround = true;
    } else if (minOverlap === overlapBottom && entity.vy < 0) {
      entity.y = platform.y + platform.height;
      entity.vy = 0;
    } else if (minOverlap === overlapLeft) {
      entity.x = platform.x - width;
      entity.vx = 0;
    } else if (minOverlap === overlapRight) {
      entity.x = platform.x + platform.width;
      entity.vx = 0;
    }
  }
}

function blockOverlapsOthers(block, ignore = null) {
  const rect = getBlockRect(block);
  for (const other of blocks) {
    if (other === block || other === ignore) continue;
    if (rectsOverlap(rect, getBlockRect(other))) return true;
  }
  return false;
}

function findNearestBlock() {
  let nearest = null;
  let nearestDist = Infinity;

  for (const block of blocks) {
    if (block.carried) continue;

    const dx = block.x + block.size / 2 - (player.x + player.width / 2);
    const dy = block.y + block.size / 2 - (player.y + player.height / 2);
    const dist = Math.hypot(dx, dy);

    if (dist < 70 && dist < nearestDist) {
      nearest = block;
      nearestDist = dist;
    }
  }

  return nearest;
}

function tryPickUpOrDrop() {
  if (carriedBlock) {
    const dropX = player.x + player.width / 2 - carriedBlock.size / 2;
    const dropY = player.y - carriedBlock.size - 4;

    carriedBlock.x = dropX;
    carriedBlock.y = dropY;
    carriedBlock.carried = false;

    resolvePlatformCollisions(carriedBlock, carriedBlock.size, carriedBlock.size);

    if (blockOverlapsOthers(carriedBlock)) {
      carriedBlock.x = player.x + player.width / 2 - carriedBlock.size / 2;
      carriedBlock.y = player.y - carriedBlock.size;
      carriedBlock.carried = true;
      statusEl.textContent = "Can't drop here — something is in the way.";
      return;
    }

    statusEl.textContent = "Block dropped. Move it somewhere else!";
    carriedBlock = null;
    return;
  }

  const target = findNearestBlock();
  if (target) {
    target.carried = true;
    carriedBlock = target;
    statusEl.textContent = "Carrying a block — press E to drop it.";
  } else {
    statusEl.textContent = "No block nearby. Walk closer and try again.";
  }
}

function updatePlayer() {
  if (keys["ArrowLeft"] || keys["a"] || keys["A"]) {
    player.vx -= MOVE_SPEED;
  }
  if (keys["ArrowRight"] || keys["d"] || keys["D"]) {
    player.vx += MOVE_SPEED;
  }

  player.vx *= FRICTION;
  player.vx = Math.max(-MAX_SPEED, Math.min(MAX_SPEED, player.vx));

  if ((keys[" "] || keys["ArrowUp"] || keys["w"] || keys["W"]) && player.onGround) {
    player.vy = JUMP_FORCE;
    player.onGround = false;
  }

  player.vy += GRAVITY;
  player.x += player.vx;
  player.y += player.vy;

  if (player.x < 0) {
    player.x = 0;
    player.vx = 0;
  }
  if (player.x + player.width > canvas.width) {
    player.x = canvas.width - player.width;
    player.vx = 0;
  }

  resolvePlatformCollisions(player, player.width, player.height);

  if (carriedBlock) {
    carriedBlock.x = player.x + player.width / 2 - carriedBlock.size / 2;
    carriedBlock.y = player.y - carriedBlock.size - 4;
  }
}

function drawRoundedRect(x, y, w, h, color) {
  ctx.fillStyle = color;
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = "rgba(255,255,255,0.15)";
  ctx.fillRect(x, y, w, h * 0.25);
}

function draw() {
  ctx.fillStyle = "#87ceeb";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.fillStyle = "rgba(255,255,255,0.35)";
  for (let i = 0; i < 6; i++) {
    ctx.beginPath();
    ctx.arc(80 + i * 130, 60 + (i % 2) * 20, 28, 0, Math.PI * 2);
    ctx.fill();
  }

  for (const platform of platforms) {
    drawRoundedRect(platform.x, platform.y, platform.width, platform.height, "#5d4037");
    ctx.fillStyle = "#7cb342";
    ctx.fillRect(platform.x, platform.y, platform.width, 6);
  }

  for (const block of blocks) {
    const rect = getBlockRect(block);
    drawRoundedRect(rect.x, rect.y, rect.width, rect.height, block.color);
    ctx.strokeStyle = "rgba(0,0,0,0.25)";
    ctx.lineWidth = 2;
    ctx.strokeRect(rect.x + 1, rect.y + 1, rect.width - 2, rect.height - 2);
  }

  drawRoundedRect(player.x, player.y, player.width, player.height, player.color);

  ctx.fillStyle = "#fff";
  ctx.fillRect(player.x + 10, player.y + 14, 5, 5);
  ctx.fillRect(player.x + 18, player.y + 14, 5, 5);

  if (carriedBlock) {
    ctx.fillStyle = "rgba(255,255,255,0.8)";
    ctx.font = "14px Segoe UI, sans-serif";
    ctx.fillText("↑ carrying", player.x - 4, player.y - 10);
  } else {
    const nearby = findNearestBlock();
    if (nearby) {
      ctx.strokeStyle = "#fff";
      ctx.lineWidth = 2;
      ctx.setLineDash([4, 4]);
      ctx.strokeRect(nearby.x - 4, nearby.y - 4, nearby.size + 8, nearby.size + 8);
      ctx.setLineDash([]);
    }
  }
}

function loop() {
  updatePlayer();
  draw();
  requestAnimationFrame(loop);
}

window.addEventListener("keydown", (e) => {
  keys[e.key] = true;

  if (e.key === "e" || e.key === "E") {
    tryPickUpOrDrop();
    e.preventDefault();
  }

  if (e.key === " " || e.key === "ArrowUp" || e.key === "ArrowDown") {
    e.preventDefault();
  }
});

window.addEventListener("keyup", (e) => {
  keys[e.key] = false;
});

placeBlocksOnPlatforms();
player.y = platforms[0].y - player.height;
loop();
