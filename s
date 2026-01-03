<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Web Peternakan + History Berat</title>
<style>
:root {
  --bg-light: linear-gradient(135deg,#d4f1c5,#a0e3b0);
  --bg-dark: #121212;
  --text-light: #333;
  --text-dark: #f0f0f0;
  --form-light: rgba(255,255,255,0.9);
  --form-dark: rgba(30,30,30,0.95);
  --profit: green;
  --loss: red;
  --neutral: gray;
  --warning-bg: #fff3cd;
  --warning-color: #856404;
}
body { font-family: Arial,sans-serif; margin:20px; background:var(--bg-light); color:var(--text-light); transition:all 0.3s ease; }
body.dark { background:var(--bg-dark); color:var(--text-dark); }
h1,h2{text-align:center;}
form { background:var(--form-light); padding:15px; border-radius:8px; margin-bottom:20px; box-shadow:0 0 10px rgba(0,0,0,0.1); transition:all 0.3s ease; }
body.dark form { background:var(--form-dark);}
input,select,button { width:100%; padding:8px; margin:6px 0; }
button { background:#28a745; color:white; border:none; cursor:pointer; }
button.delete { background:#dc3545; }
ul { list-style:none; padding:0; }
li { background:var(--form-light); margin:6px 0; padding:10px; border-radius:5px; box-shadow:0 0 5px rgba(0,0,0,0.1); transition:all 0.3s ease; }
body.dark li { background:var(--form-dark); }
.profit { color:var(--profit); font-weight:bold; }
.loss { color:var(--loss); font-weight:bold; }
.warning { background:var(--warning-bg); color:var(--warning-color); padding:5px; border-radius:4px; margin-bottom:5px; }
.cattle-card { padding:10px; border-radius:10px; margin:10px; display:inline-block; vertical-align:top; width:250px; color:#fff; }
.cattle-card img{width:100%; height:150px; object-fit:cover; border-radius:8px;}
.modal { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); justify-content:center; align-items:center; }
.modal-content { background:#fff; padding:20px; border-radius:8px; width:300px; position:relative; transition:all 0.3s ease; }
body.dark .modal-content { background:#333; color:#f0f0f0; }
.modal-content h3 { text-align:center; margin-top:0; }
.modal-content input { width:100%; margin:10px 0; padding:8px; }
.modal-content button { width:48%; margin:5px 1%; }
.close { position:absolute; top:5px; right:10px; cursor:pointer; font-weight:bold; }
#dark-mode-toggle { margin-bottom:10px; background:#6c757d; }
#reset-data { margin-bottom:20px; background:#dc3545; }
</style>
</head>
<body>

<h1>Web Peternakan + History Berat</h1>
<button id="dark-mode-toggle">Mode Gelap</button>
<button id="reset-data">Reset Semua Data</button>

<h2>Tambah Pengeluaran</h2>
<form id="expense-form">
<select id="exp-category" required>
<option value="">Pilih Kategori</option>
<option>Pakan Sapi</option>
<option>Perawatan Kandang</option>
<option>Obat Ternak</option>
<option>Lainnya</option>
</select>
<input id="exp-amount" placeholder="Jumlah (Rp)" required>
<input type="date" id="exp-date" required>
<button type="submit">Tambah Pengeluaran</button>
</form>

<h2>Tambah Ternak</h2>
<form id="cattle-form">
<input id="cattle-id" placeholder="ID / Nama Sapi" required>
<input type="date" id="entry-date" required>
<input id="buy-price" placeholder="Harga Beli (Rp)" required>
<input type="file" id="cattle-photo" accept="image/*">
<button type="submit">Tambah Ternak</button>
</form>

<div id="warnings"></div>

<h2>Daftar Sapi</h2>
<input id="search-cattle" placeholder="Cari Sapi by ID/Nama">
<div id="cattle-cards"></div>

<h2>Daftar Pengeluaran</h2>
<ul id="expense-list"></ul>

<!-- MODAL JUAL SAPI -->
<div class="modal" id="sell-modal">
  <div class="modal-content">
    <span class="close" id="modal-close">&times;</span>
    <h3>Jual Sapi</h3>
    <label>Harga Jual (Rp)</label>
    <input type="text" id="sell-price-input" placeholder="6,000,000">
    <label>Tanggal Keluar</label>
    <input type="date" id="sell-date-input">
    <div style="text-align:center;">
      <button id="sell-confirm">Jual</button>
      <button id="sell-cancel">Batal</button>
    </div>
  </div>
</div>

<!-- MODAL TAMBAH BERAT -->
<div class="modal" id="weight-modal">
  <div class="modal-content">
    <span class="close" id="weight-close">&times;</span>
    <h3>Tambah Berat Badan</h3>
    <input type="date" id="weight-date" required>
    <input type="number" id="weight-value" placeholder="Berat (kg)" required>
    <div style="text-align:center;">
      <button id="weight-confirm">Simpan</button>
      <button id="weight-cancel">Batal</button>
    </div>
  </div>
</div>

<script>
let expenses = JSON.parse(localStorage.getItem('expenses')) || [];
let cattle   = JSON.parse(localStorage.getItem('cattle')) || [];
let currentSellIndex = null;
let currentWeightIndex = null;

// format rupiah
const rupiah = n => typeof n==='number'&&!isNaN(n)?n.toLocaleString('id-ID'):'0';
function currencyInput(id){
    document.getElementById(id).addEventListener('input', function(){
        let value = this.value.replace(/[^0-9]/g,'');
        if(value) this.value = rupiah(parseInt(value));
        else this.value = '';
    });
}
currencyInput('exp-amount'); currencyInput('buy-price'); currencyInput('sell-price-input');

// tanggal hari ini
function today(id){ document.getElementById(id).value = new Date().toISOString().split('T')[0]; }
today('exp-date'); today('entry-date'); today('sell-date-input'); today('weight-date');

const colors = ['#f8b195','#c06c84','#6c5b7b','#355c7d','#f67280','#99b898','#ff847c','#2a363b'];

// hitung total pakan per sapi
function calculateFeedPerCow(cow){
    let total = 0;
    const entry = new Date(cow.entryDate);
    const exit  = cow.exitDate ? new Date(cow.exitDate) : new Date();
    expenses.filter(e => e.category==='Pakan Sapi').forEach(e=>{
        const d = new Date(e.date);
        if(d < entry || d > exit) return;
        const activeCows = cattle.filter(c=>{ const inDate = new Date(c.entryDate); const outDate = c.exitDate ? new Date(c.exitDate) : new Date(); return d >= inDate && d <= outDate; }).length;
        if(activeCows>0) total += e.amount / activeCows;
    });
    return Math.round(total);
}

// RENDER KOTAK SAPI DENGAN HISTORY BERAT
function renderCattleCards(filter=''){
  const container=document.getElementById('cattle-cards');
  container.innerHTML='';
  cattle.filter(c=>c.id.toLowerCase().includes(filter.toLowerCase())).forEach((cow,i)=>{
    const bgColor = colors[i % colors.length];
    let imgHTML = cow.photo? `<img src="${cow.photo}">` : '';
    let weightsHTML='';
    if(cow.weights && cow.weights.length>0){
      weightsHTML='<table border="1" style="width:100%;text-align:center;background:#fff;color:#000;"><tr><th>Bulan</th><th>Berat (kg)</th></tr>';
      cow.weights.sort((a,b)=> new Date(a.date)-new Date(b.date)).forEach(w=>{
        weightsHTML+=`<tr><td>${w.date}</td><td>${w.weight}</td></tr>`;
      });
      weightsHTML+='</table>';
    }
    container.innerHTML+=`
      <div class="cattle-card" style="background:${bgColor}">
        ${imgHTML}
        <h3>${cow.id}</h3>
        Masuk: ${cow.entryDate}<br>
        Beli: Rp ${rupiah(cow.buyPrice)}<br>
        ${cow.exitDate ? `Keluar: ${cow.exitDate}<br>Jual: Rp ${rupiah(cow.sellPrice)}<br>Pakan: Rp ${rupiah(cow.feedCost||0)}`:''}
        <h4>History Berat Badan</h4>
        ${weightsHTML}
        <button onclick="openWeightModal(${i})">Tambah Berat</button>
        ${!cow.exitDate?`<button onclick="openSellModal(${i})">Jual / Keluar</button>`:''}
        <button class="delete" onclick="deleteCattle(${i})">Hapus Sapi</button>
      </div>
    `;
  });
}

// modal jual sapi
const sellModal = document.getElementById('sell-modal');
const sellClose = document.getElementById('modal-close');
const sellCancel = document.getElementById('sell-cancel');
const sellConfirm = document.getElementById('sell-confirm');
function openSellModal(i){
    currentSellIndex=i;
    document.getElementById('sell-price-input').value='';
    document.getElementById('sell-date-input').value=new Date().toISOString().split('T')[0];
    sellModal.style.display='flex';
}
sellClose.onclick = sellCancel.onclick = ()=>sellModal.style.display='none';
sellConfirm.onclick=()=>{
    const priceInput=document.getElementById('sell-price-input').value;
    const sellPrice=parseInt(priceInput.replace(/[^0-9]/g,''));
    const sellDate=document.getElementById('sell-date-input').value;
    if(!sellPrice||!sellDate) return alert('Harga jual dan tanggal keluar harus diisi');
    const cow=cattle[currentSellIndex];
    cow.sellPrice=sellPrice;
    cow.exitDate=sellDate;
    cow.feedCost=calculateFeedPerCow(cow);
    localStorage.setItem('cattle',JSON.stringify(cattle));
    sellModal.style.display='none';
    renderCattleCards(document.getElementById('search-cattle').value);
};

// modal berat badan
const weightModal=document.getElementById('weight-modal');
const weightClose=document.getElementById('weight-close');
const weightCancel=document.getElementById('weight-cancel');
const weightConfirm=document.getElementById('weight-confirm');
function openWeightModal(i){
    currentWeightIndex=i;
    document.getElementById('weight-value').value='';
    document.getElementById('weight-date').value=new Date().toISOString().split('T')[0];
    weightModal.style.display='flex';
}
weightClose.onclick = weightCancel.onclick = ()=>weightModal.style.display='none';
weightConfirm.onclick=()=>{
    const cow=cattle[currentWeightIndex];
    const date=document.getElementById('weight-date').value;
    const weight=parseFloat(document.getElementById('weight-value').value);
    if(!date||!weight) return alert('Tanggal dan berat harus diisi');
    if(!cow.weights) cow.weights=[];
    cow.weights.push({date,weight});
    localStorage.setItem('cattle',JSON.stringify(cattle));
    weightModal.style.display='none';
    renderCattleCards(document.getElementById('search-cattle').value);
};

// delete sapi
function deleteCattle(i){ if(confirm('Hapus data sapi permanen?')){ cattle.splice(i,1); localStorage.setItem('cattle',JSON.stringify(cattle)); renderCattleCards(document.getElementById('search-cattle').value);}}

// render pengeluaran
function renderExpenses(){
    const list=document.getElementById('expense-list');
    list.innerHTML='';
    expenses.forEach((e,i)=>{
        list.innerHTML+=`<li>${e.category} - Rp ${rupiah(e.amount)} (${e.date}) <button class="delete" onclick="deleteExpense(${i})">Hapus</button></li>`;
    });
}
function deleteExpense(i){ if(confirm('Hapus pengeluaran?')){ expenses.splice(i,1); localStorage.setItem('expenses',JSON.stringify(expenses)); renderExpenses(); renderCattleCards(document.getElementById('search-cattle').value);}}

// FORM SUBMIT
document.getElementById('expense-form').onsubmit=e=>{
    e.preventDefault();
    const category=document.getElementById('exp-category').value;
    const amount=parseInt(document.getElementById('exp-amount').value.replace(/[^0-9]/g,''));
    const date=document.getElementById('exp-date').value;
    expenses.push({category,amount,date});
    localStorage.setItem('expenses',JSON.stringify(expenses));
    renderExpenses();
    renderCattleCards(document.getElementById('search-cattle').value);
};
document.getElementById('cattle-form').onsubmit=e=>{
    e.preventDefault();
    const id=document.getElementById('cattle-id').value;
    const entryDate=document.getElementById('entry-date').value;
    const buyPrice=parseInt(document.getElementById('buy-price').value.replace(/[^0-9]/g,''));
    const photoInput=document.getElementById('cattle-photo');
    let photo='';
    if(photoInput.files && photoInput.files[0]){
        const reader=new FileReader();
        reader.onload=(e)=>{ photo=e.target.result; addCattle(id,entryDate,buyPrice,photo); };
        reader.readAsDataURL(photoInput.files[0]);
    }else addCattle(id,entryDate,buyPrice,photo);
};
function addCattle(id,entryDate,buyPrice,photo){
    cattle.push({id,entryDate,buyPrice,photo});
    localStorage.setItem('cattle',JSON.stringify(cattle));
    renderCattleCards(document.getElementById('search-cattle').value);
}

document.getElementById('search-cattle').oninput=e=>renderCattleCards(e.target.value);
document.getElementById('dark-mode-toggle').onclick=()=>document.body.classList.toggle('dark');
document.getElementById('reset-data').onclick=()=>{ if(confirm('Reset semua data?')){ localStorage.clear(); location.reload();}};

// inisialisasi
renderExpenses(); renderCattleCards();
</script>

</body>
</html>
