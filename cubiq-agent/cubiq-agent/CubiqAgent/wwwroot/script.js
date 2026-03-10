/* ================================================
   CUBIQ — Shop Logic
   ================================================ */

// ── DATA ────────────────────────────────────────
const MATERIALS = {
  wood:   { label: 'Walnut Wood',    baseColor: '#7a4f2d', edgeColor: '#4a2c12', topColor: '#9b6b40' },
  metal:  { label: 'Brushed Steel',  baseColor: '#9aa5aa', edgeColor: '#6b787d', topColor: '#c2cdd1' },
  marble: { label: 'Carrara Marble', baseColor: '#ddd8cf', edgeColor: '#b8b2a8', topColor: '#e8e4dc' },
  glass:  { label: 'Optical Glass',  baseColor: 'rgba(180,220,255,0.35)', edgeColor: 'rgba(100,180,240,0.4)', topColor: 'rgba(220,240,255,0.55)' },
  rubber: { label: 'Vulcanized Rubber', baseColor: '#1e1e1e', edgeColor: '#111', topColor: '#2a2a2a' },
  resin:  { label: 'Cast Resin',     baseColor: '#c9a84c', edgeColor: '#8a6f2e', topColor: '#e8c87a' },
};

const COLORS = {
  onyx:    { label: 'Onyx',    hex: '#1a1a1a' },
  ivory:   { label: 'Ivory',   hex: '#f5f0e8' },
  cobalt:  { label: 'Cobalt',  hex: '#1b4fcf' },
  crimson: { label: 'Crimson', hex: '#c0392b' },
  gold:    { label: 'Gold',    hex: '#c9a84c' },
  sage:    { label: 'Sage',    hex: '#6b8f6b' },
  slate:   { label: 'Slate',   hex: '#5c6b7a' },
  blush:   { label: 'Blush',   hex: '#e8a090' },
};

const SIZES = {
  xs: { label: 'XS', dim: '2×2×2 cm',  px: 38,  weight: '12g',   basePrice: 29 },
  s:  { label: 'S',  dim: '5×5×5 cm',  px: 60,  weight: '85g',   basePrice: 59 },
  m:  { label: 'M',  dim: '10×10×10 cm',px: 88, weight: '680g',  basePrice: 129 },
  l:  { label: 'L',  dim: '20×20×20 cm',px: 120,weight: '5.4 kg',basePrice: 289 },
};

const MATERIAL_MULTIPLIER = { wood: 1.2, metal: 1.8, marble: 2.2, glass: 2.6, rubber: 0.9, resin: 1.5 };
const COLOR_NAMES = Object.keys(COLORS);
const MATERIAL_NAMES = Object.keys(MATERIALS);
const SIZE_NAMES = Object.keys(SIZES);

// ── GENERATE PRODUCTS ───────────────────────────
function generateProducts() {
  const products = [];
  let id = 1;

  // Curated combos (4 per material = 24 products)
  const combos = [
    { m:'wood',   c:'onyx',    s:'m'  },
    { m:'wood',   c:'ivory',   s:'s'  },
    { m:'wood',   c:'sage',    s:'l'  },
    { m:'wood',   c:'cobalt',  s:'xs' },
    { m:'metal',  c:'slate',   s:'m'  },
    { m:'metal',  c:'onyx',    s:'l'  },
    { m:'metal',  c:'cobalt',  s:'s'  },
    { m:'metal',  c:'ivory',   s:'xs' },
    { m:'marble', c:'ivory',   s:'l'  },
    { m:'marble', c:'crimson', s:'m'  },
    { m:'marble', c:'slate',   s:'s'  },
    { m:'marble', c:'gold',    s:'xs' },
    { m:'glass',  c:'cobalt',  s:'m'  },
    { m:'glass',  c:'blush',   s:'s'  },
    { m:'glass',  c:'sage',    s:'l'  },
    { m:'glass',  c:'ivory',   s:'xs' },
    { m:'rubber', c:'onyx',    s:'m'  },
    { m:'rubber', c:'crimson', s:'s'  },
    { m:'rubber', c:'cobalt',  s:'l'  },
    { m:'rubber', c:'gold',    s:'xs' },
    { m:'resin',  c:'gold',    s:'m'  },
    { m:'resin',  c:'blush',   s:'s'  },
    { m:'resin',  c:'sage',    s:'l'  },
    { m:'resin',  c:'crimson', s:'xs' },
  ];

  combos.forEach(({ m, c, s }) => {
    const mat  = MATERIALS[m];
    const col  = COLORS[c];
    const size = SIZES[s];
    const price = Math.round(size.basePrice * MATERIAL_MULTIPLIER[m]);
    const isFeatured = (id <= 4);

    products.push({
      id: id++,
      material: m,
      color: c,
      size: s,
      name: `${col.label} ${mat.label}`,
      price,
      weight: size.weight,
      dim: size.dim,
      featured: isFeatured,
    });
  });

  return products;
}

const ALL_PRODUCTS = generateProducts();

// ── STATE ────────────────────────────────────────
let filters = { material: 'all', size: 'all', color: 'all' };
let sortBy = 'default';
let cart = [];

// ── RENDER CUBE SVG (CSS 3D) ─────────────────────
function renderMiniCube(product, size) {
  const mat = MATERIALS[product.material];
  const col = COLORS[product.color];
  const px = SIZES[product.size].px;

  // Blend material colour with the colour tint
  const tint = col.hex;

  const faceStyle = (which) => {
    const bases = {
      front:  mat.baseColor,
      back:   mat.edgeColor,
      left:   mat.edgeColor,
      right:  mat.edgeColor,
      top:    mat.topColor,
      bottom: mat.edgeColor,
    };
    const base = bases[which];
    // For glass/resin we keep translucency; otherwise blend with color
    if (product.material === 'glass') {
      return `background:${base}; border: 1px solid rgba(201,168,76,0.25);`;
    }
    if (product.material === 'marble') {
      return `background:${base}; border: 1px solid rgba(0,0,0,0.1);`;
    }
    // Tint with the product color via a small overlay trick using box-shadow inset
    return `background: color-mix(in srgb, ${base} 55%, ${tint} 45%); border: 1px solid rgba(0,0,0,0.2);`;
  };

  const half = px / 2;
  const wrapSize = px * 2.2;

  return `
    <div style="width:${wrapSize}px;height:${wrapSize}px;perspective:${px*5}px;display:flex;align-items:center;justify-content:center;">
      <div class="mini-cube" style="width:${px}px;height:${px}px;transform-style:preserve-3d;animation:miniSpin 8s linear infinite;">
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('front')}transform:translateZ(${half}px);"></div>
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('back')}transform:rotateY(180deg) translateZ(${half}px);"></div>
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('left')}transform:rotateY(-90deg) translateZ(${half}px);"></div>
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('right')}transform:rotateY(90deg) translateZ(${half}px);"></div>
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('top')}transform:rotateX(90deg) translateZ(${half}px);"></div>
        <div class="mini-face" style="width:${px}px;height:${px}px;${faceStyle('bottom')}transform:rotateX(-90deg) translateZ(${half}px);"></div>
      </div>
    </div>`;
}

// ── RENDER PRODUCTS ──────────────────────────────
function getFilteredProducts() {
  let list = [...ALL_PRODUCTS];
  if (filters.material !== 'all') list = list.filter(p => p.material === filters.material);
  if (filters.size !== 'all')     list = list.filter(p => p.size === filters.size);
  if (filters.color !== 'all')    list = list.filter(p => p.color === filters.color);

  if (sortBy === 'price-asc')  list.sort((a,b) => a.price - b.price);
  if (sortBy === 'price-desc') list.sort((a,b) => b.price - a.price);
  if (sortBy === 'name')       list.sort((a,b) => a.name.localeCompare(b.name));

  return list;
}

function renderProducts() {
  const grid = document.getElementById('productsGrid');
  const noRes = document.getElementById('noResults');
  const count = document.getElementById('resultsCount');
  const list = getFilteredProducts();

  count.textContent = list.length;

  if (list.length === 0) {
    grid.innerHTML = '';
    noRes.style.display = 'block';
    return;
  }
  noRes.style.display = 'none';

  grid.innerHTML = list.map((p, i) => `
    <div class="product-card" data-product-id="${p.id}" style="animation-delay:${i * 0.04}s">
      <div class="product-visual" style="background: rgba(0,0,0,0.2);">
        <div class="product-visual-inner">
          ${renderMiniCube(p)}
        </div>
        ${p.featured ? `<div class="product-badge">Featured</div>` : ''}
      </div>
      <div class="product-info">
        <div class="product-material">${MATERIALS[p.material].label}</div>
        <div class="product-name">${p.name}</div>
        <div class="product-size">
          ${SIZES[p.size].label} &nbsp;·&nbsp; ${p.dim} &nbsp;·&nbsp; ${p.weight}
        </div>
        <div class="product-footer">
          <div class="product-price">€${p.price}</div>
          <button class="add-to-cart" onclick="addToCart(${p.id})">+ ADD</button>
        </div>
      </div>
    </div>
  `).join('');
}

// ── FILTERS ──────────────────────────────────────
function initFilters() {
  document.querySelectorAll('.pill').forEach(btn => {
    btn.addEventListener('click', () => {
      const filterType = btn.dataset.filter;
      const val = btn.dataset.value;

      // Deactivate siblings
      document.querySelectorAll(`.pill[data-filter="${filterType}"]`).forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      filters[filterType] = val;
      renderProducts();
    });
  });

  document.getElementById('sortSelect').addEventListener('change', (e) => {
    sortBy = e.target.value;
    renderProducts();
  });
}

function resetFilters() {
  filters = { material: 'all', size: 'all', color: 'all' };
  sortBy = 'default';
  document.querySelectorAll('.pill').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.pill[data-value="all"]').forEach(b => b.classList.add('active'));
  document.getElementById('sortSelect').value = 'default';
  renderProducts();
}

// ── CART ─────────────────────────────────────────
function addToCart(productId) {
  const product = ALL_PRODUCTS.find(p => p.id === productId);
  if (!product) return;

  const existing = cart.find(i => i.id === productId);
  if (existing) {
    existing.qty++;
  } else {
    cart.push({ ...product, qty: 1 });
  }

  updateCartUI();
  showToast(`${product.name} (${SIZES[product.size].label}) added to cart`);
  openCart();
}

function removeFromCart(productId) {
  cart = cart.filter(i => i.id !== productId);
  updateCartUI();
}

function changeQty(productId, delta) {
  const item = cart.find(i => i.id === productId);
  if (!item) return;
  item.qty = Math.max(1, item.qty + delta);
  updateCartUI();
}

function updateCartUI() {
  const totalItems = cart.reduce((s, i) => s + i.qty, 0);
  document.getElementById('cartCount').textContent = totalItems;

  const cartItems = document.getElementById('cartItems');
  const cartFooter = document.getElementById('cartFooter');

  if (cart.length === 0) {
    cartItems.innerHTML = '<p class="cart-empty">Your cart is empty.</p>';
    cartFooter.style.display = 'none';
    return;
  }

  cartFooter.style.display = 'block';
  const total = cart.reduce((s, i) => s + i.price * i.qty, 0);
  document.getElementById('cartTotal').textContent = `€${total}`;

  cartItems.innerHTML = cart.map(item => `
    <div class="cart-item">
      <div class="cart-item-cube">
        ${renderCartCube(item)}
      </div>
      <div class="cart-item-info">
        <div class="cart-item-name">${item.name}</div>
        <div class="cart-item-meta">
          ${SIZES[item.size].label} · ${SIZES[item.size].dim}
        </div>
        <div class="cart-item-controls">
          <button class="qty-btn" onclick="changeQty(${item.id}, -1)">−</button>
          <span class="qty-num">${item.qty}</span>
          <button class="qty-btn" onclick="changeQty(${item.id}, +1)">+</button>
          <button class="remove-item" onclick="removeFromCart(${item.id})" title="Remove">✕</button>
        </div>
      </div>
      <div class="cart-item-price">€${item.price * item.qty}</div>
    </div>
  `).join('');
}

function renderCartCube(product) {
  const px = 32;
  const mat = MATERIALS[product.material];
  const col = COLORS[product.color];
  const half = px / 2;
  const tint = col.hex;

  const face = (which) => {
    const bases = { front: mat.baseColor, back: mat.edgeColor, left: mat.edgeColor, right: mat.edgeColor, top: mat.topColor, bottom: mat.edgeColor };
    const base = bases[which];
    if (product.material === 'glass') return `background:${base};border:1px solid rgba(201,168,76,0.25);`;
    return `background:color-mix(in srgb, ${base} 55%, ${tint} 45%);border:1px solid rgba(0,0,0,0.2);`;
  };

  return `<div style="width:56px;height:56px;perspective:180px;display:flex;align-items:center;justify-content:center;">
    <div style="width:${px}px;height:${px}px;transform-style:preserve-3d;animation:miniSpin 6s linear infinite;">
      <div style="position:absolute;width:${px}px;height:${px}px;${face('front')}transform:translateZ(${half}px);"></div>
      <div style="position:absolute;width:${px}px;height:${px}px;${face('back')}transform:rotateY(180deg) translateZ(${half}px);"></div>
      <div style="position:absolute;width:${px}px;height:${px}px;${face('left')}transform:rotateY(-90deg) translateZ(${half}px);"></div>
      <div style="position:absolute;width:${px}px;height:${px}px;${face('right')}transform:rotateY(90deg) translateZ(${half}px);"></div>
      <div style="position:absolute;width:${px}px;height:${px}px;${face('top')}transform:rotateX(90deg) translateZ(${half}px);"></div>
      <div style="position:absolute;width:${px}px;height:${px}px;${face('bottom')}transform:rotateX(-90deg) translateZ(${half}px);"></div>
    </div>
  </div>`;
}

// ── CART PANEL ───────────────────────────────────
function openCart() {
  document.getElementById('cartSidebar').classList.add('open');
  document.getElementById('cartOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeCart() {
  document.getElementById('cartSidebar').classList.remove('open');
  document.getElementById('cartOverlay').classList.remove('open');
  document.body.style.overflow = '';
}

// ── TOAST ────────────────────────────────────────
function showToast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(window._toastTimer);
  window._toastTimer = setTimeout(() => t.classList.remove('show'), 2800);
}

// ── CANVAS HOLOGRAM CUBE (rAF — never pauses) ────
function initHoloCanvas() {
  const canvas = document.getElementById('holoCanvas');
  const ctx = canvas.getContext('2d');
  const W = 260, H = 260;
  canvas.width = W; canvas.height = H;

  const colorList = ['#c9a84c', '#1b4fcf', '#c0392b', '#6b8f6b', '#5c6b7a', '#e8a090'];
  let colorIdx = 0;
  let accentColor = colorList[0];
  setInterval(() => {
    colorIdx = (colorIdx + 1) % colorList.length;
    accentColor = colorList[colorIdx];
    const label = document.querySelector('#floatingHolo .holo-label');
    if (label) label.style.color = accentColor + 'aa';
  }, 2200);

  // Half-size of cube. Keep small enough to always fit in 260px canvas.
  const S = 68;

  // 8 vertices of a centered cube
  const verts = [
    [-S,-S,-S], [ S,-S,-S], [ S, S,-S], [-S, S,-S],  // back  0-3
    [-S,-S, S], [ S,-S, S], [ S, S, S], [-S, S, S],  // front 4-7
  ];

  // 6 faces: vertex indices (wound CCW from outside), outward normal, fill alpha
  const faces = [
    { idx:[4,5,6,7], norm:[ 0, 0, 1], alpha:0.12 }, // front  +Z
    { idx:[1,0,3,2], norm:[ 0, 0,-1], alpha:0.05 }, // back   -Z
    { idx:[0,4,7,3], norm:[-1, 0, 0], alpha:0.08 }, // left   -X
    { idx:[5,1,2,6], norm:[ 1, 0, 0], alpha:0.08 }, // right  +X
    { idx:[7,6,2,3], norm:[ 0, 1, 0], alpha:0.16 }, // top    +Y
    { idx:[0,1,5,4], norm:[ 0,-1, 0], alpha:0.03 }, // bottom -Y
  ];

  const edges = [
    [0,1],[1,2],[2,3],[3,0],
    [4,5],[5,6],[6,7],[7,4],
    [0,4],[1,5],[2,6],[3,7],
  ];

  // Camera sits at z = -DIST, looks toward +Z
  const DIST = 480;
  const FOV  = 380;

  let angleY = 0;
  const angleX = 0.42; // fixed tilt

  function rotY(v, a) {
    const c = Math.cos(a), s = Math.sin(a);
    return [v[0]*c - v[2]*s, v[1], v[0]*s + v[2]*c];
  }
  function rotX(v, a) {
    const c = Math.cos(a), s = Math.sin(a);
    return [v[0], v[1]*c - v[2]*s, v[1]*s + v[2]*c];
  }
  function project(v) {
    const z = v[2] + DIST; // always positive, camera is far back
    return [ W/2 + v[0] * FOV / z,  H/2 + v[1] * FOV / z ];
  }
  function hexRgb(hex) {
    return [
      parseInt(hex.slice(1,3),16),
      parseInt(hex.slice(3,5),16),
      parseInt(hex.slice(5,7),16),
    ];
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);
    angleY += 0.009;

    // Transform vertices
    const tv = verts.map(v => rotX(rotY(v, angleY), angleX));
    const pv = tv.map(project);

    const [r,g,b] = hexRgb(accentColor);

    // Painter's sort: back faces first (smallest avg Z = farthest from camera)
    const sorted = [...faces].sort((a, fa) => {
      const za = a.idx.reduce((s,i) => s + tv[i][2], 0);
      const zb = fa.idx.reduce((s,i) => s + tv[i][2], 0);
      return za - zb;
    });

    for (const face of sorted) {
      // Rotate outward normal, back-face cull:
      // Camera looks in +Z; face is visible when rotated normal_z < 0
      const rn = rotX(rotY(face.norm, angleY), angleX);
      if (rn[2] > 0) continue; // facing away from camera

      const [i0,i1,i2,i3] = face.idx;
      ctx.beginPath();
      ctx.moveTo(pv[i0][0], pv[i0][1]);
      ctx.lineTo(pv[i1][0], pv[i1][1]);
      ctx.lineTo(pv[i2][0], pv[i2][1]);
      ctx.lineTo(pv[i3][0], pv[i3][1]);
      ctx.closePath();
      ctx.fillStyle   = `rgba(${r},${g},${b},${face.alpha})`;
      ctx.fill();
      ctx.strokeStyle = `rgba(${r},${g},${b},0.7)`;
      ctx.lineWidth   = 1.2;
      ctx.stroke();
    }

    // Draw all 12 edges on top
    ctx.strokeStyle = `rgba(${r},${g},${b},0.4)`;
    ctx.lineWidth = 0.8;
    for (const [a, eb] of edges) {
      ctx.beginPath();
      ctx.moveTo(pv[a][0], pv[a][1]);
      ctx.lineTo(pv[eb][0], pv[eb][1]);
      ctx.stroke();
    }

    // Scanlines
    for (let y = 0; y < H; y += 4) {
      ctx.fillStyle = `rgba(${r},${g},${b},0.015)`;
      ctx.fillRect(0, y, W, 1);
    }

    // Soft glow behind cube
    const grd = ctx.createRadialGradient(W/2, H/2, 0, W/2, H/2, 80);
    grd.addColorStop(0, `rgba(${r},${g},${b},0.07)`);
    grd.addColorStop(1, `rgba(${r},${g},${b},0)`);
    ctx.fillStyle = grd;
    ctx.fillRect(0, 0, W, H);

    requestAnimationFrame(draw);
  }

  draw();
}

// ── CUSTOM CUBE CURSOR ───────────────────────────
function initCursor() {
  const cursorEl = document.getElementById('cursorCube');
  let mx = -200, my = -200;
  let cx = -200, cy = -200;

  function loop() {
    cx += (mx - cx) * 0.14;
    cy += (my - cy) * 0.14;
    cursorEl.style.left = cx + 'px';
    cursorEl.style.top  = cy + 'px';
    requestAnimationFrame(loop);
  }

  document.addEventListener('mousemove', (e) => {
    mx = e.clientX;
    my = e.clientY;
  });

  const hoverTargets = 'a, button, .pill, .product-card, .add-to-cart, select, input';
  document.addEventListener('mouseover', (e) => {
    if (e.target.closest(hoverTargets)) document.body.classList.add('cursor-hover');
  });
  document.addEventListener('mouseout', (e) => {
    if (e.target.closest(hoverTargets)) document.body.classList.remove('cursor-hover');
  });

  document.addEventListener('mouseleave', () => { cursorEl.style.opacity = '0'; });
  document.addEventListener('mouseenter', () => { cursorEl.style.opacity = '1'; });

  loop();
}

// ── FLOATING HOLOGRAM SCROLL BEHAVIOUR ──────────
function initFloatingHolo() {
  const holo = document.getElementById('floatingHolo');
  const hero = document.querySelector('.hero');

  function onScroll() {
    const heroBottom = hero.getBoundingClientRect().bottom;
    if (heroBottom < 80) {
      holo.classList.add('scrolled-past');
    } else {
      holo.classList.remove('scrolled-past');
    }
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
}

// ── INIT ─────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  renderProducts();
  initFilters();
  initHoloCanvas();
  initCursor();
  initFloatingHolo();

  document.getElementById('cartBtn').addEventListener('click', openCart);
  document.getElementById('closeCart').addEventListener('click', closeCart);
  document.getElementById('cartOverlay').addEventListener('click', closeCart);

  document.querySelector('.checkout-btn')?.addEventListener('click', () => {
    showToast('Checkout coming soon — thank you!');
    closeCart();
  });
});
