const $ = (s) => document.querySelector(s);
const post = (n, d = {}) => fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d) });
const CIRC = 364.4;
let S = { fuel: 0, tank: 60, need: 0, type: null, liters: 0, price: 0, method: 'cash', cash: 0, bank: 0 };

function setCar(d) {
  const img = $('#carimg'), fb = $('#carfb');
  const srcs = [`img/${d.spawn}.png`, (d.imgUrl || '').replace('%s', d.spawn)].filter(Boolean);
  let i = 0;
  fb.style.display = 'none'; img.style.display = 'block';
  img.onerror = () => { i++; if (i < srcs.length) img.src = srcs[i]; else { img.style.display = 'none'; fb.style.display = 'block'; } };
  img.src = srcs[0];
}

function render() {
  const pct = Math.min(100, S.fuel + (S.liters / S.tank) * 100);
  $('#arc').style.strokeDashoffset = CIRC * (1 - pct / 100);
  $('#pct').textContent = Math.round(pct) + '%';
  const a = $('#added');
  a.textContent = S.liters > 0 ? '+' + S.liters.toFixed(1) + ' L' : 'FUEL LEVEL';
  a.classList.toggle('add', S.liters > 0);
  const total = Math.round(S.liters * S.price);
  $('#total').textContent = S.free ? (S.liters > 0 ? 'FREE' : '$ 0') : '$ ' + total;
  $('#buy').disabled = S.liters <= 0 || (!S.free && total > S[S.method]);
}

function select(el, t, liters) {
  document.querySelectorAll('.card').forEach((c) => {
    if (c !== el) { c.classList.remove('active'); setCard(c, 0, 0); }
  });
  el.classList.add('active');
  S.type = t.id; S.price = t.price; S.liters = liters;
  setCard(el, liters, t.price);
  render();
}

function setCard(c, liters, price) {
  const r = c.querySelector('input');
  r.value = liters;
  r.style.setProperty('--p', (S.need > 0 ? (liters / S.need) * 100 : 0) + '%');
  c.querySelector('.lit').textContent = liters.toFixed(1) + ' L';
  c.querySelector('.cost').textContent = '$ ' + Math.round(liters * (price || c.dataset.price));
}

function build(types) {
  $('#grid').innerHTML = '';
  $('#grid').classList.toggle('full', S.need < 0.1);
  types.forEach((t) => {
    const el = document.createElement('div');
    el.className = 'card'; el.dataset.price = t.price;
    el.style.setProperty('--c', t.color);
    el.innerHTML = `<div class="top"><div class="dot">&#9981;</div><div class="price">${t.price}$ / LITER<small>${t.label.toUpperCase()}</small></div></div>
      <div class="read"><span class="lit">0.0 L</span><span class="cost">$ 0</span></div>
      <input type="range" min="0" max="${S.need.toFixed(1)}" step="0.5" value="0">
      <div class="quick"><button data-q="0.25">25%</button><button data-q="0.5">50%</button><button data-q="0.75">75%</button><button data-q="1">MAX</button></div>`;
    const input = el.querySelector('input');
    input.style.setProperty('--c', t.color);
    input.addEventListener('input', () => select(el, t, parseFloat(input.value)));
    el.querySelectorAll('.quick button').forEach((b) => b.addEventListener('click', (e) => {
      e.stopPropagation(); select(el, t, Math.round(S.need * parseFloat(b.dataset.q) * 2) / 2);
    }));
    el.addEventListener('click', () => { if (S.type !== t.id) select(el, t, 0); });
    $('#grid').appendChild(el);
  });
}

window.addEventListener('message', (e) => {
  const { action, data } = e.data;
  if (action === 'open') {
    S = { ...S, fuel: data.fuel, tank: data.tank, need: (data.tank * (100 - data.fuel)) / 100, type: null, liters: 0, price: 0, cash: data.cash, bank: data.bank, free: !!data.free };
    $('#paybox').style.display = S.free ? 'none' : '';
    $('#model').textContent = data.model;
    $('#plate').textContent = data.plate;
    $('#temp').innerHTML = data.temp + 'C&deg;';
    $('#speed').textContent = data.speed + ' KMH';
    $('#tank').textContent = data.tank + ' L';
    $('#cash').textContent = '$' + data.cash;
    $('#bank').textContent = '$' + data.bank;
    $('#need').textContent = S.need < 0.1 ? 'TANK FULL' : S.need.toFixed(1) + ' L TO FILL';
    setCar(data);
    build(data.fuelTypes);
    render();
    $('#app').classList.remove('hidden');
  } else if (action === 'close') {
    $('#app').classList.add('hidden');
  }
});

document.querySelectorAll('.pay button').forEach((b) => b.addEventListener('click', () => {
  document.querySelectorAll('.pay button').forEach((x) => x.classList.remove('on'));
  b.classList.add('on'); S.method = b.dataset.m; render();
}));
$('#buy').addEventListener('click', () => { if (S.liters > 0) post('purchase', { type: S.type, liters: S.liters, method: S.method }); });
$('#close').addEventListener('click', () => post('close'));
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') post('close'); });
setInterval(() => { $('#clock').textContent = new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }); }, 1000);
