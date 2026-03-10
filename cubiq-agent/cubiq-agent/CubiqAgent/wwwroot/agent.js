/* ================================================
   CUBIQ AI AGENT — Frontend Widget
   ================================================ */

const AGENT_API = '/api/agent/chat';

// ── State ────────────────────────────────────────
let agentOpen    = false;
let agentHistory = [];
let agentBusy    = false;
const activeCanvasLoops = new Map();

// ── Init ─────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  initAgentWidget();
  initAgentAvatarCanvas();
});

function initAgentWidget() {
  document.getElementById('agentFab').addEventListener('click', toggleAgent);
  document.getElementById('agentClose').addEventListener('click', () => setAgentOpen(false));
  document.getElementById('agentSend').addEventListener('click', sendMessage);
  document.getElementById('agentInput').addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });
}

function toggleAgent() { setAgentOpen(!agentOpen); }

function setAgentOpen(open) {
  agentOpen = open;
  document.getElementById('agentPanel').classList.toggle('open', open);
  if (open) setTimeout(() => document.getElementById('agentInput').focus(), 300);
}

// ── Send Message ─────────────────────────────────
async function sendMessage() {
  if (agentBusy) return;
  const input = document.getElementById('agentInput');
  const text  = input.value.trim();
  if (!text) return;

  input.value = '';
  hideSuggestions();
  appendMessage('user', text);
  agentHistory.push({ role: 'user', content: text });

  setAgentBusy(true);
  showTyping();

  try {
    const res  = await fetch(AGENT_API, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ messages: agentHistory })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || `Server error ${res.status}`);

    console.log('CUBIQ response:', JSON.stringify(data));

    removeTyping();
    appendMessage('assistant', data.reply);
    agentHistory.push({ role: 'assistant', content: data.reply });

    if (data.recommendations && data.recommendations.length > 0) {
      appendInlineRecommendations(data.recommendations);
    }
  } catch (err) {
    removeTyping();
    appendMessage('assistant', 'Connection error: ' + err.message + '. Please try again.');
  } finally {
    setAgentBusy(false);
  }
}

function sendSuggestion(btn) {
  document.getElementById('agentInput').value = btn.textContent;
  sendMessage();
}

// ── UI Helpers ───────────────────────────────────
function appendMessage(role, text) {
  const container = document.getElementById('agentMessages');
  const div = document.createElement('div');
  div.className = 'agent-msg ' + role;
  const p = document.createElement('p');
  if (role === 'assistant') {
    p.innerHTML = linkifyProductIds(text);
  } else {
    p.textContent = text;
  }
  div.appendChild(p);
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
}

// Only match explicit "(ID N)" patterns — nothing else
function linkifyProductIds(text) {
  const safe = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

  return safe.replace(/\(ID:?\s*(\d+)\)/gi, function(match, id) {
    return '<button class="inline-product-link" onclick="toggleInlineCubeCard(this,' + id + ')">' + match + '</button>';
  });
}

function showTyping() {
  const container = document.getElementById('agentMessages');
  const div = document.createElement('div');
  div.className = 'agent-msg assistant agent-typing';
  div.id = 'agentTyping';
  div.innerHTML = '<p><span class="dot"></span><span class="dot"></span><span class="dot"></span></p>';
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
}

function removeTyping() {
  var el = document.getElementById('agentTyping');
  if (el) el.remove();
}

function setAgentBusy(busy) {
  agentBusy = busy;
  document.getElementById('agentSend').disabled = busy;
  document.getElementById('agentInput').disabled = busy;
  const status = document.getElementById('agentStatus');
  status.textContent = busy ? 'Thinking\u2026' : 'Ready to help';
  status.className   = busy ? 'agent-status thinking' : 'agent-status';
}

function hideSuggestions() {
  const s = document.getElementById('agentSuggestions');
  if (s) s.style.display = 'none';
}

// ── Inline recommendation cards in chat ──────────
function appendInlineRecommendations(recs) {
  const container = document.getElementById('agentMessages');
  var shown = 0;

  recs.forEach(function(r, i) {
    // Coerce id to number — server may send string or number
    var pid = parseInt(r.id || r.Id, 10);
    if (isNaN(pid)) return;

    // Find product — compare as numbers both sides
    var product = ALL_PRODUCTS.find(function(p) { return p.id === pid; });
    if (!product) {
      console.warn('CUBIQ: product not found for id', pid, r);
      return;
    }

    var mat  = MATERIALS[product.material];
    var col  = COLORS[product.color];
    var size = SIZES[product.size];

    if (!mat || !col || !size) {
      console.warn('CUBIQ: missing mat/col/size for', product);
      return;
    }

    var reason = r.reason || r.Reason || '';
    var cid = 'rec_cube_' + pid + '_' + Date.now() + '_' + i;

    var wrapper = document.createElement('div');
    wrapper.className = 'agent-msg assistant';

    var card = document.createElement('div');
    card.className  = 'inline-cube-card rec-inline';
    card.dataset.id = pid;
    card.innerHTML  =
        '<div class="icc-top">'
      +   '<div class="icc-visual"><canvas id="' + cid + '" width="72" height="72"></canvas></div>'
      +   '<div class="icc-info">'
      +     '<div class="icc-material">' + mat.label + '</div>'
      +     '<div class="icc-name">' + product.name + '</div>'
      +     '<div class="icc-meta">' + size.label + ' · ' + size.dim + ' · ' + size.weight + '</div>'
      +     '<div class="icc-color"><span class="icc-swatch" style="background:' + col.hex + '"></span>' + col.label + '</div>'
      +     (reason ? '<div class="icc-reason">\u201c' + reason + '\u201d</div>' : '')
      +   '</div>'
      + '</div>'
      + '<div class="icc-footer">'
      +   '<span class="icc-price">\u20ac' + product.price + '</span>'
      +   '<button class="icc-view">VIEW IN SHOP</button>'
      +   '<button class="icc-add">+ ADD TO CART</button>'
      + '</div>';

    card.querySelector('.icc-view').addEventListener('click', function() {
      scrollToProduct(pid);
    });
    card.querySelector('.icc-add').addEventListener('click', function() {
      addToCart(pid);
      this.textContent = '\u2713 Added';
      this.style.background  = '#1a3a1a';
      this.style.color       = '#6b8f6b';
      this.style.borderColor = '#2a5a2a';
      this.disabled = true;
    });

    wrapper.appendChild(card);
    container.appendChild(wrapper);
    shown++;

    setTimeout(function(id, prod) {
      drawInlineCube(id, prod);
    }.bind(null, cid, product), i * 60);
  });

  if (shown === 0) {
    // Nothing rendered — let user know
    var fallback = document.createElement('div');
    fallback.className = 'agent-msg assistant';
    fallback.innerHTML = '<p>I found some matches — try asking me to search again or browse the shop below.</p>';
    container.appendChild(fallback);
  }

  container.scrollTop = container.scrollHeight;
}
// ── Scroll to product in shop ────────────────────
function scrollToProduct(productId) {
  document.getElementById('recHighlight').style.display = 'none';
  setAgentOpen(false);
  if (typeof resetFilters === 'function') resetFilters();
  requestAnimationFrame(function() {
    requestAnimationFrame(function() {
      const card = document.querySelector('[data-product-id="' + productId + '"]');
      if (!card) return;
      window.scrollTo({ top: card.getBoundingClientRect().top + window.scrollY - 140, behavior: 'smooth' });
      card.classList.add('agent-highlight');
      setTimeout(function() { card.classList.remove('agent-highlight'); }, 2200);
    });
  });
}

// ── Inline cube card ─────────────────────────────
function toggleInlineCubeCard(btn, productId) {
  const msgDiv = btn.closest('.agent-msg');

  // Toggle off if already open
  const existing = msgDiv.querySelector('.inline-cube-card[data-id="' + productId + '"]');
  if (existing) {
    killCanvas(existing.querySelector('canvas') ? existing.querySelector('canvas').id : null);
    existing.remove();
    btn.classList.remove('active');
    return;
  }

  // Close any other open cards
  document.querySelectorAll('.inline-cube-card').forEach(function(c) {
    killCanvas(c.querySelector('canvas') ? c.querySelector('canvas').id : null);
    c.remove();
  });
  document.querySelectorAll('.inline-product-link.active').forEach(function(b) { b.classList.remove('active'); });
  btn.classList.add('active');

  const product = ALL_PRODUCTS.find(function(p) { return p.id === productId; });
  if (!product) return;

  const mat  = MATERIALS[product.material];
  const col  = COLORS[product.color];
  const size = SIZES[product.size];
  const cid  = 'icc_' + productId + '_' + Date.now();

  const card = document.createElement('div');
  card.className  = 'inline-cube-card';
  card.dataset.id = productId;
  card.innerHTML  =
    '<div class="icc-top">'
    + '<div class="icc-visual"><canvas id="' + cid + '" width="72" height="72"></canvas></div>'
    + '<div class="icc-info">'
    + '<div class="icc-material">' + mat.label + '</div>'
    + '<div class="icc-name">' + product.name + '</div>'
    + '<div class="icc-meta">' + size.label + ' - ' + size.dim + ' - ' + size.weight + '</div>'
    + '<div class="icc-color"><span class="icc-swatch" style="background:' + col.hex + '"></span>' + col.label + '</div>'
    + '</div>'
    + '<button class="icc-close">&#x2715;</button>'
    + '</div>'
    + '<div class="icc-footer">'
    + '<span class="icc-price">€' + product.price + '</span>'
    + '<button class="icc-view">VIEW IN SHOP</button>'
    + '<button class="icc-add">+ ADD TO CART</button>'
    + '</div>';

  // Safe event listeners (no inline onclick strings)
  card.querySelector('.icc-close').addEventListener('click', function() {
    killCanvas(cid);
    card.remove();
    btn.classList.remove('active');
  });
  card.querySelector('.icc-view').addEventListener('click', function() {
    scrollToProduct(productId);
  });
  card.querySelector('.icc-add').addEventListener('click', function() {
    addToCart(productId);
    this.textContent = '\u2713 Added';
    this.style.background   = '#1a3a1a';
    this.style.color        = '#6b8f6b';
    this.style.borderColor  = '#2a5a2a';
    this.disabled = true;
  });

  msgDiv.appendChild(card);

  const msgs = document.getElementById('agentMessages');
  requestAnimationFrame(function() { msgs.scrollTop = msgs.scrollHeight; });
  requestAnimationFrame(function() { drawInlineCube(cid, product); });
}

function killCanvas(canvasId) {
  if (canvasId) activeCanvasLoops.set(canvasId, false);
}

// ── Cube canvas renderer ─────────────────────────
function drawInlineCube(canvasId, product) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  activeCanvasLoops.set(canvasId, true);

  const ctx = canvas.getContext('2d');
  const W = 72, H = 72;
  const col = COLORS[product.color];
  const tr  = parseInt(col.hex.slice(1,3), 16) || 180;
  const tg  = parseInt(col.hex.slice(3,5), 16) || 150;
  const tb  = parseInt(col.hex.slice(5,7), 16) || 50;

  const S=20, DIST=180, FOV=140;
  const V=[[-S,-S,-S],[S,-S,-S],[S,S,-S],[-S,S,-S],[-S,-S,S],[S,-S,S],[S,S,S],[-S,S,S]];
  const F=[
    {i:[4,5,6,7],n:[0,0,1],a:.14},{i:[1,0,3,2],n:[0,0,-1],a:.05},
    {i:[0,4,7,3],n:[-1,0,0],a:.08},{i:[5,1,2,6],n:[1,0,0],a:.08},
    {i:[7,6,2,3],n:[0,1,0],a:.18},{i:[0,1,5,4],n:[0,-1,0],a:.03},
  ];
  const E=[[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]];
  function ry(v,a){var c=Math.cos(a),s=Math.sin(a);return[v[0]*c-v[2]*s,v[1],v[0]*s+v[2]*c];}
  function rx(v,a){var c=Math.cos(a),s=Math.sin(a);return[v[0],v[1]*c-v[2]*s,v[1]*s+v[2]*c];}
  function pr(v){var z=v[2]+DIST;return[W/2+v[0]*FOV/z,H/2+v[1]*FOV/z];}

  var ay=0;
  function draw(){
    if(!activeCanvasLoops.get(canvasId)) return;
    ctx.clearRect(0,0,W,H); ay+=.013;
    var tv=V.map(function(v){return rx(ry(v,ay),.42);}), pv=tv.map(pr);
    var sf=F.slice().sort(function(a,b){
      return a.i.reduce(function(s,j){return s+tv[j][2];},0)-b.i.reduce(function(s,j){return s+tv[j][2];},0);
    });
    sf.forEach(function(f){
      if(rx(ry(f.n,ay),.42)[2]>0) return;
      ctx.beginPath();ctx.moveTo(pv[f.i[0]][0],pv[f.i[0]][1]);ctx.lineTo(pv[f.i[1]][0],pv[f.i[1]][1]);
      ctx.lineTo(pv[f.i[2]][0],pv[f.i[2]][1]);ctx.lineTo(pv[f.i[3]][0],pv[f.i[3]][1]);ctx.closePath();
      ctx.fillStyle='rgba('+tr+','+tg+','+tb+','+f.a+')';ctx.fill();
      ctx.strokeStyle='rgba('+tr+','+tg+','+tb+',.7)';ctx.lineWidth=.8;ctx.stroke();
    });
    ctx.strokeStyle='rgba('+tr+','+tg+','+tb+',.3)';ctx.lineWidth=.5;
    E.forEach(function(e){ctx.beginPath();ctx.moveTo(pv[e[0]][0],pv[e[0]][1]);ctx.lineTo(pv[e[1]][0],pv[e[1]][1]);ctx.stroke();});
    requestAnimationFrame(draw);
  }
  draw();
}

// ── Agent Avatar Canvas ──────────────────────────
function initAgentAvatarCanvas() {
  const canvas = document.getElementById('agentCubeCanvas');
  if (!canvas) return;
  const ctx=canvas.getContext('2d');
  const W=36,H=36; canvas.width=W; canvas.height=H;
  const S=9,DIST=120,FOV=90;
  const V=[[-S,-S,-S],[S,-S,-S],[S,S,-S],[-S,S,-S],[-S,-S,S],[S,-S,S],[S,S,S],[-S,S,S]];
  const F=[{i:[4,5,6,7],n:[0,0,1],a:.14},{i:[1,0,3,2],n:[0,0,-1],a:.05},{i:[0,4,7,3],n:[-1,0,0],a:.08},{i:[5,1,2,6],n:[1,0,0],a:.08},{i:[7,6,2,3],n:[0,1,0],a:.18},{i:[0,1,5,4],n:[0,-1,0],a:.03}];
  const E=[[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]];
  function ry(v,a){var c=Math.cos(a),s=Math.sin(a);return[v[0]*c-v[2]*s,v[1],v[0]*s+v[2]*c];}
  function rx(v,a){var c=Math.cos(a),s=Math.sin(a);return[v[0],v[1]*c-v[2]*s,v[1]*s+v[2]*c];}
  function pr(v){var z=v[2]+DIST;return[W/2+v[0]*FOV/z,H/2+v[1]*FOV/z];}
  var ay=0;
  function draw(){
    ctx.clearRect(0,0,W,H);ay+=.012;
    var tv=V.map(function(v){return rx(ry(v,ay),.42);}),pv=tv.map(pr);
    F.slice().sort(function(a,b){return a.i.reduce(function(s,j){return s+tv[j][2];},0)-b.i.reduce(function(s,j){return s+tv[j][2];},0);})
      .forEach(function(f){
        if(rx(ry(f.n,ay),.42)[2]>0) return;
        ctx.beginPath();ctx.moveTo(pv[f.i[0]][0],pv[f.i[0]][1]);ctx.lineTo(pv[f.i[1]][0],pv[f.i[1]][1]);
        ctx.lineTo(pv[f.i[2]][0],pv[f.i[2]][1]);ctx.lineTo(pv[f.i[3]][0],pv[f.i[3]][1]);ctx.closePath();
        ctx.fillStyle='rgba(201,168,76,'+f.a+')';ctx.fill();
      });
    ctx.strokeStyle='rgba(201,168,76,.8)';ctx.lineWidth=.8;
    E.forEach(function(e){ctx.beginPath();ctx.moveTo(pv[e[0]][0],pv[e[0]][1]);ctx.lineTo(pv[e[1]][0],pv[e[1]][1]);ctx.stroke();});
    requestAnimationFrame(draw);
  }
  draw();
}

// ── Bridge ───────────────────────────────────────
function addToCartById(productId) {
  if (typeof addToCart === 'function') addToCart(productId);
}
