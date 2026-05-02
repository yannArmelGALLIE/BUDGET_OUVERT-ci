import { useState } from "react";
import {
  LogOut, LayoutDashboard, Plus, List, Bell, FileText,
  TrendingUp, CheckCircle, XCircle, Clock, Send, Download,
  X, Check, Trash2, Edit3, Save, AlertTriangle
} from "lucide-react";

// ─── Data ─────────────────────────────────────────────────────────────────────

const TX_INIT = [
  { id:"T001", label:"Taxe Foncière",        service:"Dir. Financier",   category:"Administration",   type:"recette", date:"22/03/26", amount:10000000 },
  { id:"T002", label:"Réhabilitation voirie", service:"Serv. Technique",  category:"Voirie & Travaux", type:"dépense", date:"22/03/26", amount:5400000  },
  { id:"T003", label:"Subvention État",       service:"RH Commune",       category:"Administration",   type:"recette", date:"22/03/26", amount:10000000 },
  { id:"T004", label:"Salaires Agents",       service:"Régie",            category:"Administration",   type:"dépense", date:"22/03/26", amount:10000000 },
  { id:"T005", label:"Patente Commerciale",   service:"Administration",   category:"Administration",   type:"recette", date:"22/03/26", amount:18000000 },
  { id:"T006", label:"Fournitures Bureau",    service:"Administration",   category:"Administration",   type:"dépense", date:"22/03/26", amount:18000000 },
  { id:"T007", label:"Licences Marchés",      service:"Dir. Financier",   category:"Commerce",         type:"recette", date:"21/03/26", amount:7500000  },
  { id:"T008", label:"Entretien Espaces",     service:"Environnement",    category:"Environnement",    type:"dépense", date:"21/03/26", amount:3200000  },
];

const REQUESTS_INIT = [
  { id:"B001", title:"Réparation nid de poule Rue Principale", service:"Chef Voirie",        amount:2500000, date:"02/05/26", priority:"urgent", teams:["Équipe Voirie 1","Équipe Équipements"],  status:"en attente" },
  { id:"B002", title:"Élagage Avenue Centrale",                service:"Chef Environnement", amount:800000,  date:"01/05/26", priority:"normal", teams:["Équipe Environnement"],                  status:"en attente" },
  { id:"B003", title:"Réfection trottoir Mairie",              service:"Chef Voirie",        amount:4100000, date:"30/04/26", priority:"urgent", teams:["Équipe Voirie 2","Équipe Maintenance"],  status:"approuvé"   },
  { id:"B004", title:"Remplacement lampadaires Rue des Fleurs",service:"Chef Équipements",   amount:1750000, date:"29/04/26", priority:"normal", teams:["Équipe Équipements"],                   status:"refusé"     },
];

const SECTEUR_COLORS = {"Voirie & Travaux":"#0d9488","Éducation":"#f59e0b","Santé":"#10b981","Social & Culture":"#6366f1","Administration":"#f97316","Environnement":"#06b6d4"};

const BUDGET_INIT = [
  { id:"S1", secteur:"Voirie & Travaux", budget:120000000, depense:72000000,  mois:[8,9,10,11,12,13,10,9,11,10,9,8] },
  { id:"S2", secteur:"Éducation",        budget:504000000, depense:296000000, mois:[38,40,42,45,43,41,44,42,40,41,42,40] },
  { id:"S3", secteur:"Santé",            budget:375000000, depense:225000000, mois:[28,30,29,32,31,30,29,28,31,30,29,28] },
  { id:"S4", secteur:"Social & Culture", budget:87000000,  depense:57000000,  mois:[6,7,7,8,7,6,7,8,7,6,6,7] },
  { id:"S5", secteur:"Administration",   budget:200000000, depense:140000000, mois:[15,16,17,16,15,16,17,16,15,16,15,16] },
  { id:"S6", secteur:"Environnement",    budget:60000000,  depense:32000000,  mois:[4,5,5,4,4,5,4,5,4,4,4,4] },
];

const MONTHS_SHORT = ["Jan","Fév","Mar","Avr","Mai","Jun","Jul","Aoû","Sep","Oct","Nov","Déc"];

const fmt  = n => new Intl.NumberFormat("fr-FR").format(n) + " FCFA";
const fmtM = n => (n/1e6).toFixed(1) + " M";
const pct  = (a,b) => b===0 ? 0 : Math.round((a/b)*100);
const uid  = () => "T" + Date.now().toString(36).toUpperCase();

// ─── Shared UI ────────────────────────────────────────────────────────────────

const Card = ({children, style={}}) => (
  <div style={{background:"white",borderRadius:14,padding:20,border:"1px solid #e2e8f0",boxShadow:"0 1px 3px rgba(0,0,0,.04)",...style}}>
    {children}
  </div>
);

const Pill = ({children, color="#0d9488", bg}) => (
  <span style={{padding:"3px 10px",borderRadius:20,fontSize:11,fontWeight:700,background:bg||color+"18",color,whiteSpace:"nowrap"}}>{children}</span>
);

const Bar = ({value, max, color, height=8}) => (
  <div style={{height,background:"#f1f5f9",borderRadius:99,overflow:"hidden"}}>
    <div style={{height:"100%",width:`${Math.min(100,pct(value,max))}%`,background:color,borderRadius:99,transition:"width .4s"}}/>
  </div>
);

const Label = ({children}) => (
  <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>{children}</label>
);

const TextInput = ({value, onChange, type="text", placeholder="", style={}}) => (
  <input type={type} value={value} onChange={onChange} placeholder={placeholder}
    style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none",boxSizing:"border-box",...style}}/>
);

// ─── Sidebar ─────────────────────────────────────────────────────────────────

const NAV = [
  {id:"dashboard",            label:"Vue Générale",             icon:LayoutDashboard},
  {id:"nouvelle-transaction", label:"Nouvelle Transaction",      icon:Plus},
  {id:"registre",             label:"Registre des Transactions", icon:List},
  null,
  {id:"validations",          label:"Validations Budgets",       icon:Bell, badge:true},
  null,
  {id:"previsionnel",         label:"Budget Prévisionnel",       icon:TrendingUp},
  {id:"rapports",             label:"Rapports & Export",         icon:FileText},
];

function Sidebar({active, setActive, pendingCount}) {
  return (
    <aside style={{width:240,minWidth:240,background:"linear-gradient(180deg,#0f766e 0%,#134e4a 100%)",display:"flex",flexDirection:"column",boxShadow:"2px 0 12px rgba(0,0,0,.15)"}}>
      <div style={{padding:"20px 16px 16px",borderBottom:"1px solid rgba(255,255,255,.1)",display:"flex",alignItems:"center",gap:10}}>
        <div style={{width:38,height:38,background:"#f97316",borderRadius:9,display:"flex",alignItems:"center",justifyContent:"center",fontWeight:900,color:"white",fontSize:17,flexShrink:0}}>B</div>
        <div>
          <div style={{color:"white",fontWeight:700,fontSize:14}}>Budget Ouvert</div>
          <div style={{color:"#99f6e4",fontSize:10}}>Gestion Financière</div>
        </div>
      </div>
      <div style={{margin:"12px 12px 4px",padding:"10px 12px",background:"rgba(255,255,255,.08)",borderRadius:10,borderLeft:"3px solid #f97316"}}>
        <div style={{color:"white",fontWeight:700,fontSize:13}}>Bamba Konan</div>
        <div style={{color:"#5eead4",fontSize:11,marginTop:2}}>Directeur Financier</div>
      </div>
      <nav style={{flex:1,padding:"8px 10px",overflowY:"auto"}}>
        {NAV.map((item,i) => {
          if (!item) return <div key={i} style={{height:1,background:"rgba(255,255,255,.08)",margin:"6px 4px"}}/>;
          const Icon = item.icon;
          const on = active===item.id;
          return (
            <button key={item.id} onClick={()=>setActive(item.id)}
              style={{width:"100%",display:"flex",alignItems:"center",gap:10,padding:"9px 12px",borderRadius:9,border:"none",cursor:"pointer",marginBottom:2,
                background:on?"#f97316":"transparent",color:on?"white":"#a7f3d0",fontSize:13,fontWeight:on?700:400,textAlign:"left",transition:"all .15s"}}>
              <Icon size={15}/>
              <span style={{flex:1}}>{item.label}</span>
              {item.badge && pendingCount>0 && <span style={{background:"#ef4444",color:"white",borderRadius:999,fontSize:10,fontWeight:700,padding:"1px 6px"}}>{pendingCount}</span>}
            </button>
          );
        })}
      </nav>
    </aside>
  );
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

function DashboardView({transactions}) {
  const recettes = transactions.filter(t=>t.type==="recette").reduce((s,t)=>s+t.amount,0);
  const depenses = transactions.filter(t=>t.type==="dépense").reduce((s,t)=>s+t.amount,0);
  const kpis = [
    {label:"Budget Voté 2026",    value:"4,2 Mds",     sub:"FCFA – Exercice en cours", color:"#0d9488",bg:"#f0fdfa"},
    {label:"Recettes Encaissées", value:fmtM(recettes), sub:"Total enregistré",         color:"#10b981",bg:"#f0fdf4"},
    {label:"Dépenses Effectuées", value:fmtM(depenses), sub:"Total engagé",             color:"#ef4444",bg:"#fef2f2"},
    {label:"Solde Disponible",    value:fmtM(recettes-depenses), sub:"Disponible immédiatement", color:"#f97316",bg:"#fff7ed"},
  ];
  return (
    <div>
      <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:20}}>Tableau de Bord</h2>
      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:14,marginBottom:22}}>
        {kpis.map((k,i)=>(
          <div key={i} style={{background:k.bg,borderRadius:14,padding:"18px 20px",border:"1px solid #e2e8f0"}}>
            <div style={{fontSize:11,color:"#64748b",fontWeight:600,marginBottom:8,textTransform:"uppercase",letterSpacing:".04em"}}>{k.label}</div>
            <div style={{fontSize:22,fontWeight:900,color:k.color}}>{k.value}</div>
            <div style={{fontSize:10,color:"#94a3b8",marginTop:5}}>{k.sub}</div>
          </div>
        ))}
      </div>
      <div style={{display:"grid",gridTemplateColumns:"1.2fr 1fr",gap:18}}>
        <Card>
          <div style={{fontWeight:700,color:"#134e4a",marginBottom:18,fontSize:14}}>Exécution budgétaire par secteur</div>
          {BUDGET_INIT.map((s,i)=>{
            const c = SECTEUR_COLORS[s.secteur];
            return (
              <div key={i} style={{marginBottom:14}}>
                <div style={{display:"flex",justifyContent:"space-between",marginBottom:5}}>
                  <span style={{fontSize:12,fontWeight:600,color:"#374151"}}>{s.secteur}</span>
                  <span style={{fontSize:11,color:"#6b7280"}}>{fmtM(s.depense)} / {fmtM(s.budget)} <span style={{fontWeight:700,color:c}}>{pct(s.depense,s.budget)}%</span></span>
                </div>
                <Bar value={s.depense} max={s.budget} color={c}/>
              </div>
            );
          })}
        </Card>
        <div style={{display:"flex",flexDirection:"column",gap:14}}>
          <Card>
            <div style={{fontWeight:700,color:"#134e4a",marginBottom:12,fontSize:14}}>Flux du mois — Avril 2026</div>
            <div style={{display:"flex",gap:10}}>
              {[{label:"Recettes",v:"+18,4 M",c:"#10b981",bg:"#f0fdf4"},{label:"Dépenses",v:"-12,1 M",c:"#ef4444",bg:"#fef2f2"}].map(k=>(
                <div key={k.label} style={{flex:1,background:k.bg,borderRadius:10,padding:"14px 16px"}}>
                  <div style={{fontSize:11,color:"#6b7280",fontWeight:500}}>{k.label}</div>
                  <div style={{fontSize:22,fontWeight:900,color:k.c,marginTop:4}}>{k.v}</div>
                </div>
              ))}
            </div>
          </Card>
          <Card style={{flex:1}}>
            <div style={{fontWeight:700,color:"#134e4a",marginBottom:12,fontSize:14}}>Dernières Transactions</div>
            {[...transactions].reverse().slice(0,5).map((t,i,arr)=>(
              <div key={i} style={{display:"flex",justifyContent:"space-between",alignItems:"center",padding:"9px 0",borderBottom:i<arr.length-1?"1px solid #f1f5f9":"none"}}>
                <div>
                  <div style={{fontSize:12,fontWeight:600,color:"#374151"}}>{t.label}</div>
                  <div style={{fontSize:10,color:"#94a3b8"}}>{t.date} · {t.service}</div>
                </div>
                <div style={{fontSize:13,fontWeight:800,color:t.type==="recette"?"#10b981":"#ef4444"}}>
                  {t.type==="recette"?"+":"-"}{fmtM(t.amount)}
                </div>
              </div>
            ))}
          </Card>
        </div>
      </div>
    </div>
  );
}

// ─── Nouvelle Transaction ─────────────────────────────────────────────────────

const CATS = {
  recette:["Taxe Foncière","Taxe Professionnelle","Patente Commerciale","Licences Marchés","Subvention État","Dotations","Amendes"],
  dépense:["Voirie & Travaux","Éducation","Santé","Administration","Environnement","Social & Culture","Équipements"],
};
const EMPTY_FORM = {categorie:"",date:"",service:"",reference:"",description:"",montant:""};

function NewTransactionView({onAdd}) {
  const [tab, setTab]   = useState("recette");
  const [form, setForm] = useState(EMPTY_FORM);
  const [saved, setSaved] = useState(false);
  const [err, setErr]   = useState("");
  const upd = f => e => setForm(p=>({...p,[f]:e.target.value}));
  const isRec = tab==="recette";

  const save = () => {
    if (!form.categorie || !form.date || !form.montant) { setErr("Veuillez remplir les champs obligatoires (*)"); return; }
    setErr("");
    onAdd({
      id:uid(), label:form.categorie, service:form.service||"—", category:form.categorie,
      type:tab, date:new Date(form.date).toLocaleDateString("fr-FR",{day:"2-digit",month:"2-digit",year:"2-digit"}),
      amount:parseFloat(form.montant),
    });
    setSaved(true); setForm(EMPTY_FORM); setTimeout(()=>setSaved(false),3000);
  };

  return (
    <div style={{maxWidth:640}}>
      <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:4}}>Enregistrer une Transaction</h2>
      <p style={{color:"#64748b",fontSize:13,marginBottom:22}}>Toute transaction est horodatée et immuable (registre blockchain).</p>

      <div style={{display:"flex",background:"#f1f5f9",borderRadius:11,padding:4,marginBottom:24,width:"fit-content"}}>
        {["recette","dépense"].map(t=>(
          <button key={t} onClick={()=>{setTab(t);setErr("");}}
            style={{padding:"9px 32px",borderRadius:9,border:"none",cursor:"pointer",fontWeight:700,fontSize:13,
              background:tab===t?(t==="recette"?"#10b981":"#ef4444"):"transparent",
              color:tab===t?"white":"#64748b",transition:"all .15s"}}>
            {t.charAt(0).toUpperCase()+t.slice(1)}
          </button>
        ))}
      </div>

      {saved && <div style={{background:"#f0fdf4",border:"1px solid #86efac",borderRadius:10,padding:"12px 16px",marginBottom:16,display:"flex",alignItems:"center",gap:8,color:"#166534",fontSize:13,fontWeight:600}}><CheckCircle size={16}/> Transaction enregistrée !</div>}
      {err   && <div style={{background:"#fef2f2",border:"1px solid #fca5a5",borderRadius:10,padding:"12px 16px",marginBottom:16,display:"flex",alignItems:"center",gap:8,color:"#991b1b",fontSize:13,fontWeight:600}}><AlertTriangle size={16}/> {err}</div>}

      <Card>
        <div style={{background:"#f0fdfa",borderRadius:10,padding:"14px 18px",marginBottom:22,textAlign:"center"}}>
          <div style={{fontSize:11,color:"#6b7280",marginBottom:4,fontWeight:500}}>Solde disponible actuel</div>
          <div style={{fontSize:32,fontWeight:900,color:"#0d9488"}}>590 M FCFA</div>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:14}}>
          <div>
            <Label>Catégorie *</Label>
            <select value={form.categorie} onChange={upd("categorie")}
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none"}}>
              <option value="">Sélectionner...</option>
              {CATS[tab].map(c=><option key={c}>{c}</option>)}
            </select>
          </div>
          <div><Label>Date *</Label><TextInput type="date" value={form.date} onChange={upd("date")}/></div>
          <div><Label>Service émetteur</Label><TextInput value={form.service} onChange={upd("service")} placeholder="Ex: Direction Financière"/></div>
          <div><Label>Référence</Label><TextInput value={form.reference} onChange={upd("reference")} placeholder="REC-2026-0294"/></div>
          <div style={{gridColumn:"1/-1"}}>
            <Label>Montant (FCFA) *</Label>
            <input type="number" value={form.montant} placeholder="0" onChange={upd("montant")}
              style={{width:"100%",padding:"11px 14px",borderRadius:9,border:`2px solid ${isRec?"#10b981":"#ef4444"}`,fontSize:20,fontWeight:800,outline:"none",boxSizing:"border-box",color:isRec?"#10b981":"#ef4444"}}/>
          </div>
          <div style={{gridColumn:"1/-1"}}>
            <Label>Description</Label>
            <textarea value={form.description} rows={3} placeholder="Objet de la transaction..." onChange={upd("description")}
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none",resize:"none",boxSizing:"border-box"}}/>
          </div>
          <div style={{gridColumn:"1/-1"}}>
            <Label>Pièce justificative</Label>
            <div style={{border:"2px dashed #d1d5db",borderRadius:9,padding:18,textAlign:"center",color:"#94a3b8",fontSize:12,cursor:"pointer"}}>
              Glisser un fichier ou cliquer pour choisir (PDF, JPG, PNG)
            </div>
          </div>
        </div>
        <button onClick={save}
          style={{marginTop:20,width:"100%",padding:13,background:isRec?"linear-gradient(135deg,#10b981,#059669)":"linear-gradient(135deg,#ef4444,#dc2626)",color:"white",borderRadius:10,border:"none",cursor:"pointer",fontWeight:700,fontSize:14,display:"flex",alignItems:"center",justifyContent:"center",gap:8}}>
          <Send size={16}/> Enregistrer la {tab}
        </button>
      </Card>
    </div>
  );
}

// ─── Registre ─────────────────────────────────────────────────────────────────

function RegistreView({transactions}) {
  const [filter, setFilter] = useState("tous");
  const [search, setSearch] = useState("");
  const list = transactions
    .filter(t=>filter==="tous"||t.type===filter)
    .filter(t=>t.label.toLowerCase().includes(search.toLowerCase())||t.service.toLowerCase().includes(search.toLowerCase()));
  const totalRec = list.filter(t=>t.type==="recette").reduce((s,t)=>s+t.amount,0);
  const totalDep = list.filter(t=>t.type==="dépense").reduce((s,t)=>s+t.amount,0);

  return (
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:18}}>
        <div>
          <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a"}}>Registre des Transactions</h2>
          <p style={{color:"#64748b",fontSize:13,marginTop:2}}>{list.length} enregistrement{list.length>1?"s":""} · <span style={{color:"#10b981",fontWeight:600}}>+{fmtM(totalRec)}</span> · <span style={{color:"#ef4444",fontWeight:600}}>-{fmtM(totalDep)}</span></p>
        </div>
        <button style={{display:"flex",alignItems:"center",gap:6,padding:"9px 18px",background:"#0d9488",color:"white",border:"none",borderRadius:9,cursor:"pointer",fontSize:13,fontWeight:600}}>
          <Download size={15}/> Exporter PDF
        </button>
      </div>
      <div style={{display:"flex",gap:8,marginBottom:14,alignItems:"center"}}>
        {["tous","recette","dépense"].map(f=>(
          <button key={f} onClick={()=>setFilter(f)}
            style={{padding:"6px 18px",borderRadius:20,border:"1px solid #e2e8f0",cursor:"pointer",fontSize:12,fontWeight:600,background:filter===f?"#134e4a":"white",color:filter===f?"white":"#374151",transition:"all .15s"}}>
            {f.charAt(0).toUpperCase()+f.slice(1)}
          </button>
        ))}
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Rechercher..."
          style={{marginLeft:"auto",padding:"7px 14px",borderRadius:9,border:"1px solid #e2e8f0",fontSize:13,outline:"none",width:200}}/>
      </div>
      <Card style={{padding:0,overflow:"hidden"}}>
        <table style={{width:"100%",borderCollapse:"collapse"}}>
          <thead>
            <tr style={{background:"#f8fafc",borderBottom:"2px solid #e2e8f0"}}>
              {["Description","Service","Catégorie","Type","Date","Montant (FCFA)"].map(h=>(
                <th key={h} style={{padding:"11px 14px",textAlign:"left",fontSize:11,fontWeight:700,color:"#6b7280",textTransform:"uppercase",letterSpacing:".04em"}}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {list.length===0 && <tr><td colSpan={6} style={{padding:32,textAlign:"center",color:"#94a3b8",fontSize:13}}>Aucune transaction trouvée.</td></tr>}
            {list.map((t,i)=>(
              <tr key={t.id} style={{borderBottom:"1px solid #f1f5f9",background:i%2?"#fafafa":"white"}}>
                <td style={{padding:"11px 14px",fontSize:13,fontWeight:600,color:"#374151"}}>{t.label}</td>
                <td style={{padding:"11px 14px",fontSize:12,color:"#6b7280"}}>{t.service}</td>
                <td style={{padding:"11px 14px",fontSize:12,color:"#6b7280"}}>{t.category}</td>
                <td style={{padding:"11px 14px"}}>
                  <span style={{padding:"3px 9px",borderRadius:20,fontSize:11,fontWeight:700,background:t.type==="recette"?"#dcfce7":"#fee2e2",color:t.type==="recette"?"#166534":"#991b1b"}}>
                    {t.type==="recette"?"▲":"▼"} {t.type}
                  </span>
                </td>
                <td style={{padding:"11px 14px",fontSize:12,color:"#6b7280"}}>{t.date}</td>
                <td style={{padding:"11px 14px",fontSize:13,fontWeight:800,color:t.type==="recette"?"#10b981":"#ef4444",textAlign:"right"}}>
                  {t.type==="recette"?"+":"-"}{new Intl.NumberFormat("fr-FR").format(t.amount)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

// ─── Validations ──────────────────────────────────────────────────────────────

function ValidationsView() {
  const [reqs, setReqs] = useState(REQUESTS_INIT);
  const [sel, setSel]   = useState(null);
  const act = (id,action) => { setReqs(r=>r.map(q=>q.id===id?{...q,status:action==="approve"?"approuvé":"refusé"}:q)); setSel(null); };
  const pending = reqs.filter(r=>r.status==="en attente");
  const done    = reqs.filter(r=>r.status!=="en attente");

  return (
    <div>
      <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:4}}>Validation des Budgets</h2>
      <p style={{color:"#64748b",fontSize:13,marginBottom:22}}>Demandes transmises par les chefs de service</p>
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:20}}>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:"#374151",marginBottom:10,display:"flex",alignItems:"center",gap:8}}>
            <Clock size={14} color="#f97316"/> En attente ({pending.length})
          </div>
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {pending.length===0 && <Card><span style={{color:"#94a3b8",fontSize:13,fontStyle:"italic"}}>Aucune demande en attente</span></Card>}
            {pending.map(req=>{
              const open = sel===req.id;
              return (
                <div key={req.id} onClick={()=>setSel(open?null:req.id)}
                  style={{background:"white",borderRadius:12,padding:16,border:open?"2px solid #0d9488":"1px solid #e2e8f0",cursor:"pointer",transition:"all .15s",boxShadow:open?"0 4px 12px rgba(13,148,136,.1)":"none"}}>
                  <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:8}}>
                    <div style={{fontSize:13,fontWeight:700,color:"#374151",flex:1,marginRight:8}}>{req.title}</div>
                    <Pill color={req.priority==="urgent"?"#ef4444":"#f59e0b"}>{req.priority==="urgent"?"⚡ Urgent":"Normal"}</Pill>
                  </div>
                  <div style={{fontSize:11,color:"#6b7280",marginBottom:6}}>Par {req.service} · {req.date}</div>
                  <div style={{fontSize:16,fontWeight:800,color:"#f97316"}}>{fmt(req.amount)}</div>
                  <div style={{fontSize:11,color:"#94a3b8",marginTop:4}}>Équipes : {req.teams.join(", ")}</div>
                  {open && (
                    <div style={{display:"flex",gap:8,marginTop:12}}>
                      <button onClick={e=>{e.stopPropagation();act(req.id,"approve");}}
                        style={{flex:1,padding:9,background:"#10b981",color:"white",border:"none",borderRadius:8,cursor:"pointer",fontWeight:700,fontSize:12,display:"flex",alignItems:"center",justifyContent:"center",gap:6}}>
                        <Check size={14}/> Approuver
                      </button>
                      <button onClick={e=>{e.stopPropagation();act(req.id,"refuse");}}
                        style={{flex:1,padding:9,background:"#ef4444",color:"white",border:"none",borderRadius:8,cursor:"pointer",fontWeight:700,fontSize:12,display:"flex",alignItems:"center",justifyContent:"center",gap:6}}>
                        <X size={14}/> Refuser
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:"#374151",marginBottom:10,display:"flex",alignItems:"center",gap:8}}>
            <CheckCircle size={14} color="#10b981"/> Traitées ({done.length})
          </div>
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {done.map(req=>(
              <div key={req.id} style={{background:"white",borderRadius:12,padding:16,border:"1px solid #e2e8f0",opacity:.85}}>
                <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:6}}>
                  <div style={{fontSize:13,fontWeight:700,color:"#374151"}}>{req.title}</div>
                  <Pill color={req.status==="approuvé"?"#10b981":"#ef4444"} bg={req.status==="approuvé"?"#dcfce7":"#fee2e2"}>
                    {req.status==="approuvé"?"✓ Approuvé":"✗ Refusé"}
                  </Pill>
                </div>
                <div style={{fontSize:11,color:"#6b7280"}}>{req.service} · {req.date}</div>
                <div style={{fontSize:14,fontWeight:800,color:"#374151",marginTop:4}}>{fmt(req.amount)}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Budget Prévisionnel ──────────────────────────────────────────────────────

function PrevisionnelView() {
  const [budgets, setBudgets]   = useState(BUDGET_INIT);
  const [editing, setEditing]   = useState(null);
  const [draft, setDraft]       = useState(null);
  const [activeTab, setActiveTab] = useState("suivi");
  const [newLine, setNewLine]   = useState({secteur:"",budget:""});
  const [saved, setSaved]       = useState(false);
  const [selId, setSelId]       = useState("S1");

  const totalBudget  = budgets.reduce((s,b)=>s+b.budget,0);
  const totalDepense = budgets.reduce((s,b)=>s+b.depense,0);

  const startEdit = b => { setEditing(b.id); setDraft({...b,mois:[...b.mois]}); };
  const cancelEdit = () => { setEditing(null); setDraft(null); };
  const saveEdit = () => {
    setBudgets(bs=>bs.map(b=>b.id===draft.id?{...draft,budget:parseFloat(draft.budget)||b.budget,depense:parseFloat(draft.depense)||b.depense}:b));
    setEditing(null); setDraft(null); setSaved(true); setTimeout(()=>setSaved(false),2500);
  };
  const deleteLine = id => { setBudgets(bs=>bs.filter(b=>b.id!==id)); if(selId===id) setSelId(budgets[0]?.id); };
  const addLine = () => {
    if (!newLine.secteur||!newLine.budget) return;
    const nb = {id:"S"+Date.now(),secteur:newLine.secteur,budget:parseFloat(newLine.budget),depense:0,mois:Array(12).fill(0)};
    setBudgets(bs=>[...bs,nb]); setNewLine({secteur:"",budget:""});
  };

  const selBudget = budgets.find(b=>b.id===selId)||budgets[0];
  const TABS = [{id:"suivi",label:"Suivi Global"},{id:"saisie",label:"Saisie & Modification"},{id:"mensuel",label:"Répartition Mensuelle"}];

  return (
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:20}}>
        <div>
          <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:4}}>Budget Prévisionnel 2026</h2>
          <p style={{color:"#64748b",fontSize:13}}>Planification, saisie et suivi des dotations par secteur</p>
        </div>
        {saved && <div style={{display:"flex",alignItems:"center",gap:8,background:"#f0fdf4",border:"1px solid #86efac",borderRadius:9,padding:"9px 14px",fontSize:13,fontWeight:600,color:"#166534"}}><CheckCircle size={15}/> Modifications enregistrées</div>}
      </div>

      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:14,marginBottom:22}}>
        {[
          {label:"Budget Total Voté",  value:fmtM(totalBudget),           color:"#0d9488",bg:"#f0fdfa"},
          {label:"Exécuté à ce jour",  value:fmtM(totalDepense),          color:"#f97316",bg:"#fff7ed"},
          {label:"Taux d'exécution",   value:pct(totalDepense,totalBudget)+"%", color:"#6366f1",bg:"#eef2ff"},
          {label:"Reste à engager",    value:fmtM(totalBudget-totalDepense), color:"#10b981",bg:"#f0fdf4"},
        ].map((k,i)=>(
          <div key={i} style={{background:k.bg,borderRadius:14,padding:"16px 18px",border:"1px solid #e2e8f0"}}>
            <div style={{fontSize:11,color:"#64748b",fontWeight:600,marginBottom:6,textTransform:"uppercase",letterSpacing:".04em"}}>{k.label}</div>
            <div style={{fontSize:22,fontWeight:900,color:k.color}}>{k.value}</div>
          </div>
        ))}
      </div>

      <div style={{display:"flex",background:"#f1f5f9",borderRadius:11,padding:4,marginBottom:20,width:"fit-content",gap:2}}>
        {TABS.map(t=>(
          <button key={t.id} onClick={()=>setActiveTab(t.id)}
            style={{padding:"8px 20px",borderRadius:9,border:"none",cursor:"pointer",fontWeight:600,fontSize:13,
              background:activeTab===t.id?"white":"transparent",color:activeTab===t.id?"#0d9488":"#64748b",
              boxShadow:activeTab===t.id?"0 1px 3px rgba(0,0,0,.1)":"none",transition:"all .15s"}}>
            {t.label}
          </button>
        ))}
      </div>

      {/* ── Suivi Global ── */}
      {activeTab==="suivi" && (
        <div style={{display:"flex",flexDirection:"column",gap:16}}>
          <Card>
            <div style={{fontWeight:700,fontSize:14,color:"#374151",marginBottom:20}}>Vue d'ensemble — Budget prévu vs Réalisé</div>
            <div style={{display:"flex",alignItems:"flex-end",gap:8,height:180,paddingBottom:20}}>
              {budgets.map((s,i)=>{
                const maxB = Math.max(...budgets.map(b=>b.budget),1);
                const hB   = (s.budget/maxB)*150;
                const hD   = (s.depense/maxB)*150;
                const c    = SECTEUR_COLORS[s.secteur]||"#0d9488";
                return (
                  <div key={i} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",position:"relative"}}>
                    <div style={{display:"flex",gap:3,alignItems:"flex-end",height:150}}>
                      <div title={`Prévu: ${fmtM(s.budget)}`} style={{width:18,height:hB,background:c+"44",borderRadius:"4px 4px 0 0",border:`1px solid ${c}`}}/>
                      <div title={`Réalisé: ${fmtM(s.depense)}`} style={{width:18,height:hD,background:c,borderRadius:"4px 4px 0 0"}}/>
                    </div>
                    <div style={{fontSize:10,color:"#6b7280",fontWeight:600,marginTop:6,textAlign:"center",maxWidth:60,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>
                      {s.secteur.split(" ")[0]}
                    </div>
                  </div>
                );
              })}
            </div>
            <div style={{display:"flex",gap:20,borderTop:"1px solid #f1f5f9",paddingTop:12}}>
              <div style={{display:"flex",alignItems:"center",gap:6,fontSize:12,color:"#6b7280"}}><div style={{width:14,height:10,background:"#0d948844",border:"1px solid #0d9488",borderRadius:2}}/> Budget prévu</div>
              <div style={{display:"flex",alignItems:"center",gap:6,fontSize:12,color:"#6b7280"}}><div style={{width:14,height:10,background:"#0d9488",borderRadius:2}}/> Réalisé</div>
            </div>
          </Card>
          <Card style={{padding:0,overflow:"hidden"}}>
            <div style={{padding:"16px 20px",borderBottom:"1px solid #f1f5f9",fontWeight:700,fontSize:14,color:"#134e4a"}}>Synthèse par secteur</div>
            <table style={{width:"100%",borderCollapse:"collapse"}}>
              <thead>
                <tr style={{background:"#f8fafc"}}>
                  {["Secteur","Budget Voté","Dépensé","Reste","Taux","Progression"].map(h=>(
                    <th key={h} style={{padding:"10px 14px",textAlign:"left",fontSize:11,fontWeight:700,color:"#6b7280",textTransform:"uppercase"}}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {budgets.map((s,i)=>{
                  const p = pct(s.depense,s.budget);
                  const c = SECTEUR_COLORS[s.secteur]||"#0d9488";
                  const alerte = p>90;
                  return (
                    <tr key={i} style={{borderBottom:"1px solid #f1f5f9",background:alerte?"#fff7ed":i%2?"#fafafa":"white"}}>
                      <td style={{padding:"12px 14px"}}>
                        <div style={{display:"flex",alignItems:"center",gap:8}}>
                          <div style={{width:10,height:10,borderRadius:2,background:c,flexShrink:0}}/>
                          <span style={{fontWeight:700,color:"#374151",fontSize:13}}>{s.secteur}</span>
                          {alerte && <AlertTriangle size={13} color="#f97316"/>}
                        </div>
                      </td>
                      <td style={{padding:"12px 14px",fontSize:13,color:"#374151"}}>{fmtM(s.budget)}</td>
                      <td style={{padding:"12px 14px",fontSize:13,color:"#ef4444",fontWeight:700}}>-{fmtM(s.depense)}</td>
                      <td style={{padding:"12px 14px",fontSize:13,color:"#10b981",fontWeight:700}}>{fmtM(s.budget-s.depense)}</td>
                      <td style={{padding:"12px 14px"}}><Pill color={alerte?"#f97316":p>70?"#f59e0b":"#10b981"}>{p}%</Pill></td>
                      <td style={{padding:"12px 14px",minWidth:120}}><Bar value={s.depense} max={s.budget} color={alerte?"#f97316":c} height={7}/></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Card>
        </div>
      )}

      {/* ── Saisie ── */}
      {activeTab==="saisie" && (
        <div style={{display:"flex",flexDirection:"column",gap:14}}>
          <Card>
            <div style={{fontWeight:700,fontSize:14,color:"#134e4a",marginBottom:16}}>Ajouter un nouveau secteur budgétaire</div>
            <div style={{display:"grid",gridTemplateColumns:"1fr 1fr auto",gap:12,alignItems:"flex-end"}}>
              <div>
                <Label>Nom du secteur</Label>
                <TextInput value={newLine.secteur} onChange={e=>setNewLine(p=>({...p,secteur:e.target.value}))} placeholder="Ex: Numérique & Innovation"/>
              </div>
              <div>
                <Label>Budget alloué (FCFA)</Label>
                <TextInput type="number" value={newLine.budget} onChange={e=>setNewLine(p=>({...p,budget:e.target.value}))} placeholder="0"/>
              </div>
              <button onClick={addLine}
                style={{padding:"9px 20px",background:"#0d9488",color:"white",border:"none",borderRadius:9,cursor:"pointer",fontWeight:700,fontSize:13,whiteSpace:"nowrap"}}>
                + Ajouter
              </button>
            </div>
          </Card>

          <Card style={{padding:0,overflow:"hidden"}}>
            <div style={{padding:"16px 20px",borderBottom:"1px solid #f1f5f9",fontWeight:700,fontSize:14,color:"#134e4a"}}>Lignes budgétaires — édition directe</div>
            {budgets.map((s,i)=>{
              const isEdit = editing===s.id;
              const c = SECTEUR_COLORS[s.secteur]||"#6366f1";
              return (
                <div key={s.id} style={{padding:"14px 20px",borderBottom:"1px solid #f1f5f9",background:isEdit?"#f0fdfa":i%2?"#fafafa":"white"}}>
                  {isEdit ? (
                    <div>
                      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:12,marginBottom:12}}>
                        {[["Secteur","secteur","text"],["Budget alloué (FCFA)","budget","number"],["Dépensé à ce jour (FCFA)","depense","number"]].map(([lbl,field,type])=>(
                          <div key={field}>
                            <Label>{lbl}</Label>
                            <input type={type} value={draft[field]} onChange={e=>setDraft(p=>({...p,[field]:e.target.value}))}
                              style={{width:"100%",padding:"8px 10px",borderRadius:8,border:"1px solid #0d9488",fontSize:13,outline:"none",boxSizing:"border-box",background:"white"}}/>
                          </div>
                        ))}
                      </div>
                      <div style={{display:"flex",gap:8}}>
                        <button onClick={saveEdit} style={{padding:"8px 20px",background:"#0d9488",color:"white",border:"none",borderRadius:8,cursor:"pointer",fontWeight:700,fontSize:12,display:"flex",alignItems:"center",gap:6}}><Save size={13}/> Enregistrer</button>
                        <button onClick={cancelEdit} style={{padding:"8px 16px",background:"#f1f5f9",color:"#374151",border:"1px solid #e2e8f0",borderRadius:8,cursor:"pointer",fontWeight:600,fontSize:12}}>Annuler</button>
                      </div>
                    </div>
                  ) : (
                    <div style={{display:"flex",alignItems:"center",gap:16}}>
                      <div style={{width:10,height:10,borderRadius:2,background:c,flexShrink:0}}/>
                      <div style={{flex:1}}>
                        <div style={{fontSize:13,fontWeight:700,color:"#374151"}}>{s.secteur}</div>
                        <div style={{fontSize:11,color:"#6b7280",marginTop:2}}>Budget : {fmtM(s.budget)} · Dépensé : {fmtM(s.depense)} · Taux : {pct(s.depense,s.budget)}%</div>
                      </div>
                      <div style={{width:120}}><Bar value={s.depense} max={s.budget} color={c} height={6}/></div>
                      <button onClick={()=>startEdit(s)}
                        style={{padding:"6px 12px",background:"#f0fdfa",color:"#0d9488",border:"1px solid #99f6e4",borderRadius:7,cursor:"pointer",fontWeight:600,fontSize:12,display:"flex",alignItems:"center",gap:5}}>
                        <Edit3 size={12}/> Modifier
                      </button>
                      <button onClick={()=>deleteLine(s.id)}
                        style={{padding:"6px 10px",background:"#fef2f2",color:"#ef4444",border:"1px solid #fca5a5",borderRadius:7,cursor:"pointer",display:"flex",alignItems:"center"}}>
                        <Trash2 size={13}/>
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </Card>
        </div>
      )}

      {/* ── Mensuel ── */}
      {activeTab==="mensuel" && selBudget && (()=>{
        const c = SECTEUR_COLORS[selBudget.secteur]||"#6366f1";
        const totalSaisi = selBudget.mois.reduce((s,v)=>s+v,0);
        const budgetM    = (selBudget.budget/1e6);
        const updMois = (mi,val) => setBudgets(bs=>bs.map(b=>b.id===selBudget.id?{...b,mois:b.mois.map((v,i)=>i===mi?val:v)}:b));

        return (
          <div style={{display:"flex",flexDirection:"column",gap:16}}>
            <Card>
              <div style={{fontWeight:700,fontSize:14,color:"#374151",marginBottom:12}}>Sélectionner un secteur</div>
              <div style={{display:"flex",flexWrap:"wrap",gap:8}}>
                {budgets.map(b=>{
                  const bc = SECTEUR_COLORS[b.secteur]||"#6366f1";
                  const sel = selId===b.id;
                  return (
                    <button key={b.id} onClick={()=>setSelId(b.id)}
                      style={{padding:"7px 16px",borderRadius:20,border:`2px solid ${sel?bc:"#e2e8f0"}`,cursor:"pointer",fontSize:12,fontWeight:600,
                        background:sel?bc+"18":"white",color:sel?bc:"#374151",transition:"all .15s"}}>
                      {b.secteur}
                    </button>
                  );
                })}
              </div>
            </Card>

            <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:16}}>
              <Card>
                <div style={{fontWeight:700,fontSize:14,color:"#374151",marginBottom:4}}>{selBudget.secteur}</div>
                <div style={{fontSize:11,color:"#6b7280",marginBottom:16}}>Saisie mensuelle prévisionnelle (M FCFA)</div>
                <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8}}>
                  {MONTHS_SHORT.map((m,mi)=>(
                    <div key={mi} style={{display:"flex",alignItems:"center",gap:8}}>
                      <span style={{fontSize:11,color:"#6b7280",width:28,flexShrink:0,fontWeight:mi<4?700:400}}>{m}</span>
                      <input type="number" value={selBudget.mois[mi]}
                        onChange={e=>updMois(mi,parseFloat(e.target.value)||0)}
                        style={{width:"100%",padding:"5px 8px",borderRadius:7,border:"1px solid #e2e8f0",fontSize:12,outline:"none",textAlign:"right",
                          borderColor:mi<4?c:"#e2e8f0",background:mi<4?c+"10":"white"}}/>
                      <span style={{fontSize:10,color:"#94a3b8",flexShrink:0}}>M</span>
                    </div>
                  ))}
                </div>
                <div style={{marginTop:14,padding:"10px 12px",background:"#f8fafc",borderRadius:8,display:"flex",justifyContent:"space-between",alignItems:"center"}}>
                  <span style={{fontSize:12,color:"#6b7280",fontWeight:600}}>Total mensuel</span>
                  <span style={{fontSize:14,fontWeight:900,color:totalSaisi>budgetM?"#ef4444":"#0d9488"}}>{totalSaisi.toFixed(1)} M / {budgetM.toFixed(0)} M</span>
                </div>
              </Card>

              <Card>
                <div style={{fontWeight:700,fontSize:14,color:"#374151",marginBottom:16}}>Graphique mensuel</div>
                <div style={{display:"flex",alignItems:"flex-end",gap:3,height:150,marginBottom:8}}>
                  {selBudget.mois.map((v,mi)=>{
                    const maxV = Math.max(...selBudget.mois,1);
                    const h = (v/maxV)*130;
                    const real = mi<4;
                    return (
                      <div key={mi} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:2}}>
                        <div style={{fontSize:8,color:c,fontWeight:700,minHeight:10}}>{v>0?v:""}</div>
                        <div style={{width:"100%",height:h,background:real?c:c+"44",borderRadius:"3px 3px 0 0",border:real?`1px solid ${c}`:"none",minHeight:v>0?2:0,transition:"height .3s"}}/>
                        <div style={{fontSize:9,color:"#9ca3af"}}>{m}</div>
                      </div>
                    );
                  })}
                </div>
                <div style={{display:"flex",gap:14,marginBottom:14}}>
                  {[[c,"Réalisé"],[c+"44","Prévisionnel"]].map(([bg,l])=>(
                    <div key={l} style={{display:"flex",alignItems:"center",gap:5,fontSize:11,color:"#6b7280"}}>
                      <div style={{width:10,height:10,background:bg,borderRadius:2,border:l==="Prévisionnel"?`1px solid ${c}`:"none"}}/> {l}
                    </div>
                  ))}
                </div>
                <div style={{borderTop:"1px solid #f1f5f9",paddingTop:14}}>
                  {[
                    {label:"Budget annuel",    v:fmtM(selBudget.budget)},
                    {label:"Dépensé",          v:fmtM(selBudget.depense), c:"#ef4444"},
                    {label:"Taux d'exécution", v:pct(selBudget.depense,selBudget.budget)+"%", c},
                    {label:"Reste à engager",  v:fmtM(selBudget.budget-selBudget.depense), c:"#10b981"},
                  ].map((k,i)=>(
                    <div key={i} style={{display:"flex",justifyContent:"space-between",padding:"6px 0",borderBottom:i<3?"1px solid #f8fafc":"none"}}>
                      <span style={{fontSize:12,color:"#6b7280"}}>{k.label}</span>
                      <span style={{fontSize:12,fontWeight:700,color:k.c||"#374151"}}>{k.v}</span>
                    </div>
                  ))}
                </div>
              </Card>
            </div>
          </div>
        );
      })()}
    </div>
  );
}

// ─── Rapports ─────────────────────────────────────────────────────────────────

const RAPPORTS = [
  {id:"r1",title:"Rapport Mensuel — Avril 2026",       type:"Mensuel",     date:"30/04/2026",pages:12,size:"1.4 MB"},
  {id:"r2",title:"Rapport Trimestriel Q1 2026",         type:"Trimestriel", date:"31/03/2026",pages:28,size:"3.2 MB"},
  {id:"r3",title:"Registre Complet des Transactions",   type:"Export",      date:"02/05/2026",pages:45,size:"5.8 MB"},
  {id:"r4",title:"Rapport d'Exécution Budgétaire",      type:"Annuel",      date:"01/01/2026",pages:64,size:"8.1 MB"},
  {id:"r5",title:"Rapport de Transparence Citoyen",     type:"Public",      date:"15/04/2026",pages: 8,size:"0.9 MB"},
];
const RPT_COLOR = {Mensuel:"#0d9488",Trimestriel:"#6366f1",Export:"#f97316",Annuel:"#10b981",Public:"#ec4899"};

function RapportsView() {
  const [dl, setDl] = useState(null);
  const download = id => { setDl(id); setTimeout(()=>setDl(null),2000); };
  return (
    <div>
      <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:4}}>Rapports & Export</h2>
      <p style={{color:"#64748b",fontSize:13,marginBottom:20}}>Générez et téléchargez les rapports financiers officiels</p>
      <div style={{background:"linear-gradient(135deg,#0f766e,#0d9488)",borderRadius:14,padding:22,marginBottom:20,color:"white"}}>
        <div style={{fontWeight:700,fontSize:14,marginBottom:12}}>Générer un nouveau rapport</div>
        <div style={{display:"flex",gap:10}}>
          <select style={{flex:1,padding:"9px 12px",borderRadius:9,border:"none",fontSize:13,outline:"none"}}>
            {["Rapport Mensuel","Rapport Trimestriel","Export Registre","Rapport Annuel","Rapport Transparence Citoyen"].map(o=><option key={o}>{o}</option>)}
          </select>
          <input type="month" defaultValue="2026-05" style={{padding:"9px 12px",borderRadius:9,border:"none",fontSize:13,outline:"none"}}/>
          <button style={{padding:"9px 24px",background:"#f97316",color:"white",border:"none",borderRadius:9,cursor:"pointer",fontWeight:700,fontSize:13,whiteSpace:"nowrap"}}>Générer PDF</button>
        </div>
      </div>
      <Card style={{padding:0,overflow:"hidden"}}>
        {RAPPORTS.map((r,i)=>{
          const c = RPT_COLOR[r.type]||"#6b7280";
          return (
            <div key={r.id} style={{display:"flex",alignItems:"center",padding:"14px 20px",borderBottom:i<RAPPORTS.length-1?"1px solid #f1f5f9":"none",gap:14}}>
              <div style={{width:40,height:40,borderRadius:10,background:c+"18",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                <FileText size={17} color={c}/>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:13,fontWeight:700,color:"#374151"}}>{r.title}</div>
                <div style={{fontSize:11,color:"#94a3b8",marginTop:2}}>{r.date} · {r.pages} pages · {r.size}</div>
              </div>
              <Pill color={c}>{r.type}</Pill>
              <button onClick={()=>download(r.id)}
                style={{display:"flex",alignItems:"center",gap:6,padding:"7px 16px",background:dl===r.id?"#10b981":"#f8fafc",color:dl===r.id?"white":"#374151",border:"1px solid #e2e8f0",borderRadius:8,cursor:"pointer",fontSize:12,fontWeight:600,transition:"all .2s"}}>
                {dl===r.id?<><Check size={13}/> Téléchargé</>:<><Download size={13}/> Télécharger</>}
              </button>
            </div>
          );
        })}
      </Card>
    </div>
  );
}

// ─── Root ─────────────────────────────────────────────────────────────────────

const TITLES = {
  dashboard:"Tableau de Bord","nouvelle-transaction":"Nouvelle Transaction",
  registre:"Registre des Transactions",validations:"Validations Budgets",
  previsionnel:"Budget Prévisionnel",rapports:"Rapports & Export",
};

export const FinancialDirectorDashboard = ({onLogout}) => {
  const [view, setView]       = useState("dashboard");
  const [transactions, setTx] = useState(TX_INIT);
  const pendingCount = REQUESTS_INIT.filter(r=>r.status==="en attente").length;

  const VIEWS = {
    dashboard:             <DashboardView transactions={transactions}/>,
    "nouvelle-transaction":<NewTransactionView onAdd={tx=>setTx(p=>[...p,tx])}/>,
    registre:              <RegistreView transactions={transactions}/>,
    validations:           <ValidationsView/>,
    previsionnel:          <PrevisionnelView/>,
    rapports:              <RapportsView/>,
  };

  return (
    <div style={{display:"flex",height:"100vh",fontFamily:"'Segoe UI',system-ui,sans-serif",background:"#f0f4f8",overflow:"hidden"}}>
      <Sidebar active={view} setActive={setView} pendingCount={pendingCount}/>
      <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
        <header style={{background:"linear-gradient(to right,#0f766e,#0d9488)",padding:"0 28px",height:60,display:"flex",alignItems:"center",justifyContent:"space-between",boxShadow:"0 2px 10px rgba(0,0,0,.15)",flexShrink:0}}>
          <div style={{display:"flex",alignItems:"center",gap:14}}>
            <div style={{width:40,height:40,background:"#f97316",borderRadius:9,display:"flex",alignItems:"center",justifyContent:"center",fontWeight:900,color:"white",fontSize:18,flexShrink:0}}>B</div>
            <div>
              <div style={{color:"white",fontWeight:800,fontSize:16}}>Budget Ouvert — Directeur Financier</div>
              <div style={{color:"#99f6e4",fontSize:11}}>Gestion des Finances Municipales · Abidjan</div>
            </div>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:12}}>
            <span style={{color:"#ccfbf1",fontSize:13,fontWeight:500}}>{TITLES[view]}</span>
            <button onClick={onLogout}
              style={{display:"flex",alignItems:"center",gap:7,padding:"7px 16px",background:"rgba(255,255,255,.15)",color:"white",border:"1px solid rgba(255,255,255,.2)",borderRadius:8,cursor:"pointer",fontSize:13,fontWeight:600}}>
              <LogOut size={15}/> Déconnexion
            </button>
          </div>
        </header>
        <main style={{flex:1,overflowY:"auto",padding:"24px 28px"}}>
          {VIEWS[view]??<DashboardView transactions={transactions}/>}
        </main>
      </div>
    </div>
  );
};

export default FinancialDirectorDashboard;