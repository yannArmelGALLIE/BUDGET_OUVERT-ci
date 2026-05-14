// @ts-nocheck
// src/pages/FinancialDirectorDashboard.jsx
// ──────────────────────────────────────────────bv───────────────────────────────
// Dashboard Directeur Financier — connecté au smart contract BudgetRegistry
// Les transactions sont enregistrées sur Polygon Amoy (ou simulées en local)
// ─────────────────────────────────────────────────────────────────────────────

import { useState } from "react";
import {
  LogOut, LayoutDashboard, Plus, List, Bell, FileText,
  TrendingUp, CheckCircle, Clock, Send, Download,
  X, Check, Trash2, Edit3, Save, AlertTriangle, ExternalLink,
  Loader, Shield,
} from "lucide-react";
import { useBlockchain } from "../lib/useBlockchain";
import { BlockchainBanner } from "../components/BlockchainBanner";

// ── Utilitaires ───────────────────────────────────────────────────────────────
const fmt  = n => new Intl.NumberFormat("fr-FR").format(Math.abs(n)) + " FCFA";
const fmtM = n => (Math.abs(n)/1e6).toFixed(1) + " M";
const pct  = (a,b) => b===0 ? 0 : Math.round((a/b)*100);
const uid  = () => "T" + Date.now().toString(36).toUpperCase();

// ── Catégories ────────────────────────────────────────────────────────────────
const CATS = {
  recette: ["Taxe Foncière","Taxe Professionnelle","Patente Commerciale",
            "Licences Marchés","Subvention État","Dotations FDCT","Amendes","Autres recettes"],
  dépense: ["Voirie & Travaux","Éducation","Santé","Administration",
            "Environnement","Social & Culture","Équipements","Personnel","Autres dépenses"],
};

const BUDGET_INIT = [
  { id:"S1", secteur:"Voirie & Travaux", budget:120000000 },
  { id:"S2", secteur:"Éducation",        budget:504000000 },
  { id:"S3", secteur:"Santé",            budget:375000000 },
  { id:"S4", secteur:"Administration",   budget:200000000 },
  { id:"S5", secteur:"Environnement",    budget:60000000  },
];

const SECTEUR_COLORS = {
  "Voirie & Travaux":"#0d9488","Éducation":"#f59e0b","Santé":"#10b981",
  "Administration":"#f97316","Environnement":"#06b6d4","Social & Culture":"#6366f1",
};

// ── Composants partagés ───────────────────────────────────────────────────────
const Card = ({children, style={}}) => (
  <div style={{background:"white",borderRadius:14,padding:20,border:"1px solid #e2e8f0",
    boxShadow:"0 1px 3px rgba(0,0,0,.04)",...style}}>{children}</div>
);

const Bar = ({value,max,color,height=8}) => (
  <div style={{height,background:"#f1f5f9",borderRadius:99,overflow:"hidden"}}>
    <div style={{height:"100%",width:`${Math.min(100,pct(value,max))}%`,
      background:color,borderRadius:99,transition:"width .4s"}}/>
  </div>
);

// ── Navigation ────────────────────────────────────────────────────────────────
const NAV = [
  {id:"dashboard",             label:"Vue Générale",              icon:LayoutDashboard},
  {id:"nouvelle-transaction",  label:"Enregistrer Transaction",   icon:Plus},
  {id:"registre",              label:"Registre Blockchain",       icon:List},
  null,
  {id:"previsionnel",          label:"Budget Prévisionnel",       icon:TrendingUp},
  {id:"rapports",              label:"Rapports & Export",         icon:FileText},
];

function Sidebar({active, setActive}) {
  return (
    <aside style={{width:240,minWidth:240,background:"linear-gradient(180deg,#0f766e,#134e4a)",
      display:"flex",flexDirection:"column",boxShadow:"2px 0 12px rgba(0,0,0,.15)"}}>
      <div style={{padding:"20px 16px 16px",borderBottom:"1px solid rgba(255,255,255,.1)",
        display:"flex",alignItems:"center",gap:10}}>
        <div style={{width:38,height:38,background:"#f97316",borderRadius:9,display:"flex",
          alignItems:"center",justifyContent:"center",fontWeight:900,color:"white",fontSize:17}}>B</div>
        <div>
          <div style={{color:"white",fontWeight:700,fontSize:14}}>Budget Ouvert</div>
          <div style={{color:"#99f6e4",fontSize:10}}>Dir. Financier</div>
        </div>
      </div>
      <div style={{margin:"12px 12px 4px",padding:"10px 12px",background:"rgba(255,255,255,.08)",
        borderRadius:10,borderLeft:"3px solid #f97316"}}>
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
              style={{width:"100%",display:"flex",alignItems:"center",gap:10,padding:"9px 12px",
                borderRadius:9,border:"none",cursor:"pointer",marginBottom:2,
                background:on?"#f97316":"transparent",color:on?"white":"#a7f3d0",
                fontSize:13,fontWeight:on?700:400,textAlign:"left",transition:"all .15s"}}>
              <Icon size={15}/>
              <span style={{flex:1}}>{item.label}</span>
            </button>
          );
        })}
      </nav>
    </aside>
  );
}

// ── Dashboard principal ───────────────────────────────────────────────────────
function DashboardView() {
  const { transactions, totalRecettes, totalDepenses, balance, loading, mode } = useBlockchain();

  const kpis = [
    {label:"Budget Voté 2026",    value:"4,2 Mds",        sub:"FCFA – Exercice en cours",  color:"#0d9488",bg:"#f0fdfa"},
    {label:"Recettes Encaissées", value:fmtM(totalRecettes), sub:`${transactions.filter(t=>t.type==="recette").length} transactions`, color:"#10b981",bg:"#f0fdf4"},
    {label:"Dépenses Effectuées", value:fmtM(totalDepenses), sub:`${transactions.filter(t=>t.type==="dépense").length} transactions`, color:"#ef4444",bg:"#fef2f2"},
    {label:"Solde Disponible",    value:fmtM(balance),    sub:`Solde ${balance>=0?"excédentaire":"déficitaire"}`, color:balance>=0?"#f97316":"#ef4444",bg:balance>=0?"#fff7ed":"#fef2f2"},
  ];

  // Calcul dépenses par secteur pour les barres
  const budgets = BUDGET_INIT.map(s => {
    const dep = transactions
      .filter(t => t.type === "dépense" && t.category.includes(s.secteur.split(" ")[0]))
      .reduce((sum, t) => sum + t.amount, 0);
    return { ...s, depense: dep };
  });

  return (
    <div>
      <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:20}}>
        <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a"}}>Tableau de Bord</h2>
        {loading && <span style={{fontSize:12,color:"#94a3b8"}}>Chargement blockchain...</span>}
        <div style={{marginLeft:"auto",fontSize:11,padding:"4px 12px",borderRadius:20,
          background:mode==="real"?"#dcfce7":"#fef3c7",
          color:mode==="real"?"#166534":"#92400e",fontWeight:700}}>
          {mode==="real" ? "⛓ Données blockchain" : "⚡ Simulation locale"}
        </div>
      </div>

      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:14,marginBottom:22}}>
        {kpis.map((k,i)=>(
          <div key={i} style={{background:k.bg,borderRadius:14,padding:"18px 20px",border:"1px solid #e2e8f0"}}>
            <div style={{fontSize:11,color:"#64748b",fontWeight:600,marginBottom:8,
              textTransform:"uppercase",letterSpacing:".04em"}}>{k.label}</div>
            <div style={{fontSize:22,fontWeight:900,color:k.color}}>{k.value}</div>
            <div style={{fontSize:10,color:"#94a3b8",marginTop:5}}>{k.sub}</div>
          </div>
        ))}
      </div>

      <div style={{display:"grid",gridTemplateColumns:"1.2fr 1fr",gap:18}}>
        <Card>
          <div style={{fontWeight:700,color:"#134e4a",marginBottom:18,fontSize:14}}>
            Exécution budgétaire par secteur
          </div>
          {budgets.map((s,i)=>{
            const c = SECTEUR_COLORS[s.secteur] || "#0d9488";
            return (
              <div key={i} style={{marginBottom:14}}>
                <div style={{display:"flex",justifyContent:"space-between",marginBottom:5}}>
                  <span style={{fontSize:12,fontWeight:600,color:"#374151"}}>{s.secteur}</span>
                  <span style={{fontSize:11,color:"#6b7280"}}>
                    {fmtM(s.depense)} / {fmtM(s.budget)}{" "}
                    <span style={{fontWeight:700,color:c}}>{pct(s.depense,s.budget)}%</span>
                  </span>
                </div>
                <Bar value={s.depense} max={s.budget} color={c}/>
              </div>
            );
          })}
        </Card>

        <Card>
          <div style={{fontWeight:700,color:"#134e4a",marginBottom:12,fontSize:14}}>
            Dernières transactions blockchain
          </div>
          {transactions.length === 0 && (
            <div style={{color:"#94a3b8",fontSize:13,fontStyle:"italic",textAlign:"center",padding:20}}>
              Aucune transaction enregistrée
            </div>
          )}
          {[...transactions].slice(0,8).map((t,i,arr)=>(
            <div key={t.id} style={{display:"flex",justifyContent:"space-between",alignItems:"center",
              padding:"9px 0",borderBottom:i<arr.length-1?"1px solid #f1f5f9":"none"}}>
              <div>
                <div style={{fontSize:12,fontWeight:600,color:"#374151"}}>{t.category}</div>
                <div style={{fontSize:10,color:"#94a3b8"}}>{t.date} · {t.commune}</div>
              </div>
              <div style={{display:"flex",alignItems:"center",gap:8}}>
                <div style={{fontSize:13,fontWeight:800,color:t.type==="recette"?"#10b981":"#ef4444"}}>
                  {t.type==="recette"?"+":"-"}{fmtM(t.amount)}
                </div>
                {t.hash && t.hash.length > 20 && (
                  <a href={`https://amoy.polygonscan.com/tx/${t.hash}`}
                    target="_blank" rel="noopener noreferrer"
                    style={{color:"#94a3b8"}} title="Voir sur Polygonscan">
                    <ExternalLink size={11}/>
                  </a>
                )}
              </div>
            </div>
          ))}
        </Card>
      </div>
    </div>
  );
}

// ── Nouvelle Transaction — écriture blockchain ────────────────────────────────
const EMPTY = {categorie:"",date:"",service:"",description:"",montant:""};

function NewTransactionView() {
  const { recordExpense, recordRevenue, txPending, commune, mode } = useBlockchain();
  const [tab,    setTab]    = useState("recette");
  const [form,   setForm]   = useState(EMPTY);
  const [status, setStatus] = useState(null); // null | "success" | "error" | "pending"
  const [txHash, setTxHash] = useState(null);
  const [err,    setErr]    = useState("");

  const upd = f => e => setForm(p => ({...p, [f]:e.target.value}));
  const isRec = tab === "recette";

  const submit = async () => {
    if (!form.categorie || !form.montant) {
      setErr("Catégorie et montant obligatoires");
      return;
    }
    if (isNaN(Number(form.montant)) || Number(form.montant) <= 0) {
      setErr("Montant invalide");
      return;
    }
    setErr("");
    setStatus("pending");

    const payload = {
      commune,
      category:    form.categorie,
      amount:      Math.round(Number(form.montant)),
      description: form.description || form.categorie,
    };

    const result = isRec
      ? await recordRevenue(payload)
      : await recordExpense(payload);

    if (result.success) {
      setStatus("success");
      setTxHash(result.hash);
      setForm(EMPTY);
      setTimeout(() => { setStatus(null); setTxHash(null); }, 5000);
    } else {
      setStatus("error");
    }
  };

  return (
    <div style={{maxWidth:620}}>
      <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a",marginBottom:4}}>
        Enregistrer une Transaction
      </h2>
      <p style={{color:"#64748b",fontSize:13,marginBottom:22}}>
        {mode === "real"
          ? "✓ Transaction signée par MetaMask et gravée sur Polygon — immuable."
          : "⚡ Mode simulation — connecter MetaMask pour la vraie blockchain."}
      </p>

      {/* Onglets Recette / Dépense */}
      <div style={{display:"flex",background:"#f1f5f9",borderRadius:11,padding:4,marginBottom:24,width:"fit-content"}}>
        {["recette","dépense"].map(t=>(
          <button key={t} onClick={()=>{setTab(t);setErr("");setStatus(null);}}
            style={{padding:"9px 32px",borderRadius:9,border:"none",cursor:"pointer",
              fontWeight:700,fontSize:13,
              background:tab===t?(t==="recette"?"#10b981":"#ef4444"):"transparent",
              color:tab===t?"white":"#64748b",transition:"all .15s"}}>
            {t === "recette" ? "▲ Recette" : "▼ Dépense"}
          </button>
        ))}
      </div>

      {/* Retour succès */}
      {status==="success" && (
        <div style={{background:"#f0fdf4",border:"1px solid #86efac",borderRadius:10,
          padding:"12px 16px",marginBottom:16,display:"flex",alignItems:"center",gap:8,color:"#166534",fontSize:13,fontWeight:600}}>
          <CheckCircle size={16}/>
          Transaction enregistrée{mode==="real"?" sur blockchain":""} !
          {txHash && (
            <a href={`https://amoy.polygonscan.com/tx/${txHash}`} target="_blank" rel="noopener noreferrer"
              style={{marginLeft:8,color:"#0d9488",fontSize:11,display:"flex",alignItems:"center",gap:4}}>
              Voir la preuve <ExternalLink size={10}/>
            </a>
          )}
        </div>
      )}

      {/* Retour erreur */}
      {(status==="error" || err) && (
        <div style={{background:"#fef2f2",border:"1px solid #fca5a5",borderRadius:10,
          padding:"12px 16px",marginBottom:16,display:"flex",alignItems:"center",gap:8,color:"#991b1b",fontSize:13}}>
          <AlertTriangle size={16}/> {err || "Erreur lors de l'enregistrement"}
        </div>
      )}

      <Card>
        {/* Solde actuel */}
        <div style={{background:"#f0fdfa",borderRadius:10,padding:"14px 18px",marginBottom:22,textAlign:"center"}}>
          <div style={{fontSize:11,color:"#6b7280",marginBottom:4,fontWeight:500}}>Commune : {commune}</div>
          <div style={{fontSize:10,color:"#94a3b8",marginBottom:4}}>
            {mode==="real" ? "⛓ Données blockchain en temps réel" : "⚡ Simulation locale"}
          </div>
        </div>

        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:14}}>
          {/* Catégorie */}
          <div>
            <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>
              Catégorie *
            </label>
            <select value={form.categorie} onChange={upd("categorie")}
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none"}}>
              <option value="">Sélectionner...</option>
              {CATS[tab].map(c => <option key={c}>{c}</option>)}
            </select>
          </div>

          {/* Date */}
          <div>
            <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>Date</label>
            <input type="date" value={form.date} onChange={upd("date")}
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none",boxSizing:"border-box"}}/>
          </div>

          {/* Service */}
          <div>
            <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>Service émetteur</label>
            <input type="text" value={form.service} onChange={upd("service")}
              placeholder="Ex: Direction Financière"
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none",boxSizing:"border-box"}}/>
          </div>

          {/* Description */}
          <div>
            <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>Description</label>
            <input type="text" value={form.description} onChange={upd("description")}
              placeholder="Libellé de l'opération"
              style={{width:"100%",padding:"9px 12px",borderRadius:9,border:"1px solid #d1d5db",fontSize:13,outline:"none",boxSizing:"border-box"}}/>
          </div>

          {/* Montant */}
          <div style={{gridColumn:"1/-1"}}>
            <label style={{fontSize:12,fontWeight:600,color:"#374151",display:"block",marginBottom:6}}>Montant (FCFA) *</label>
            <input type="number" value={form.montant} placeholder="0"
              onChange={upd("montant")}
              style={{width:"100%",padding:"11px 14px",borderRadius:9,
                border:`2px solid ${isRec?"#10b981":"#ef4444"}`,
                fontSize:20,fontWeight:800,outline:"none",boxSizing:"border-box",
                color:isRec?"#10b981":"#ef4444"}}/>
            {form.montant && !isNaN(Number(form.montant)) && (
              <div style={{fontSize:11,color:"#94a3b8",marginTop:4}}>
                = {fmt(Number(form.montant))}
              </div>
            )}
          </div>
        </div>

        {/* Bouton submit */}
        <button onClick={submit} disabled={txPending || status==="pending"}
          style={{marginTop:20,width:"100%",padding:13,
            background:txPending
              ? "#94a3b8"
              : isRec
                ? "linear-gradient(135deg,#10b981,#059669)"
                : "linear-gradient(135deg,#ef4444,#dc2626)",
            color:"white",borderRadius:10,border:"none",
            cursor:txPending?"wait":"pointer",fontWeight:700,fontSize:14,
            display:"flex",alignItems:"center",justifyContent:"center",gap:8,
            transition:"all .2s"}}>
          {txPending ? (
            <><Loader size={16} style={{animation:"spin .7s linear infinite"}}/> Enregistrement sur blockchain...</>
          ) : (
            <><Shield size={16}/> Enregistrer la {tab} {mode==="real" ? "sur Polygon" : "(simulation)"}</>
          )}
        </button>

        {mode==="local" && (
          <p style={{fontSize:11,color:"#94a3b8",textAlign:"center",marginTop:8}}>
            Connecter MetaMask pour enregistrer sur la vraie blockchain
          </p>
        )}
      </Card>
    </div>
  );
}

// ── Registre des transactions ─────────────────────────────────────────────────
function RegistreView() {
  const { transactions, totalRecettes, totalDepenses, balance, mode, loading, refreshTransactions } = useBlockchain();
  const [filter, setFilter] = useState("tous");
  const [search, setSearch] = useState("");

  const list = transactions
    .filter(t => filter === "tous" || t.type === filter)
    .filter(t => t.category.toLowerCase().includes(search.toLowerCase()) ||
                 t.description?.toLowerCase().includes(search.toLowerCase()));

  return (
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:18}}>
        <div>
          <h2 style={{fontSize:22,fontWeight:800,color:"#134e4a"}}>Registre Blockchain</h2>
          <p style={{color:"#64748b",fontSize:13,marginTop:2}}>
            {list.length} transaction{list.length>1?"s":""} ·{" "}
            <span style={{color:"#10b981",fontWeight:600}}>+{fmtM(totalRecettes)}</span> ·{" "}
            <span style={{color:"#ef4444",fontWeight:600}}>-{fmtM(totalDepenses)}</span> ·{" "}
            Solde :{" "}
            <span style={{fontWeight:700,color:balance>=0?"#0d9488":"#ef4444"}}>{fmtM(balance)}</span>
          </p>
        </div>
        <div style={{display:"flex",gap:8}}>
          <button onClick={refreshTransactions}
            style={{display:"flex",alignItems:"center",gap:6,padding:"9px 16px",
              background:"#f0fdfa",color:"#0d9488",border:"1px solid #99f6e4",
              borderRadius:9,cursor:"pointer",fontSize:13,fontWeight:600}}>
            ↻ Actualiser
          </button>
          <button style={{display:"flex",alignItems:"center",gap:6,padding:"9px 18px",
            background:"#0d9488",color:"white",border:"none",borderRadius:9,cursor:"pointer",fontSize:13,fontWeight:600}}>
            <Download size={15}/> Exporter
          </button>
        </div>
      </div>

      {/* Filtres */}
      <div style={{display:"flex",gap:8,marginBottom:14,alignItems:"center"}}>
        {["tous","recette","dépense"].map(f=>(
          <button key={f} onClick={()=>setFilter(f)}
            style={{padding:"6px 18px",borderRadius:20,border:"1px solid #e2e8f0",cursor:"pointer",
              fontSize:12,fontWeight:600,
              background:filter===f?"#134e4a":"white",color:filter===f?"white":"#374151"}}>
            {f === "recette" ? "▲ Recettes" : f === "dépense" ? "▼ Dépenses" : "Toutes"}
          </button>
        ))}
        <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Rechercher..."
          style={{marginLeft:"auto",padding:"7px 14px",borderRadius:9,border:"1px solid #e2e8f0",
            fontSize:13,outline:"none",width:200}}/>
      </div>

      {/* Table */}
      <Card style={{padding:0,overflow:"hidden"}}>
        {loading && (
          <div style={{padding:20,textAlign:"center",color:"#94a3b8",fontSize:13}}>
            Chargement des données blockchain...
          </div>
        )}
        {!loading && list.length === 0 && (
          <div style={{padding:40,textAlign:"center",color:"#94a3b8",fontSize:13}}>
            Aucune transaction — enregistrer la première via "Enregistrer Transaction"
          </div>
        )}
        {list.length > 0 && (
          <table style={{width:"100%",borderCollapse:"collapse"}}>
            <thead>
              <tr style={{background:"#f8fafc",borderBottom:"2px solid #e2e8f0"}}>
                {["ID","Catégorie","Type","Date","Commune","Montant (FCFA)","Preuve"].map(h=>(
                  <th key={h} style={{padding:"11px 14px",textAlign:"left",fontSize:11,
                    fontWeight:700,color:"#6b7280",textTransform:"uppercase",letterSpacing:".04em"}}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {list.map((t,i)=>(
                <tr key={t.id} style={{borderBottom:"1px solid #f1f5f9",background:i%2?"#fafafa":"white"}}>
                  <td style={{padding:"11px 14px",fontSize:12,color:"#94a3b8",fontFamily:"monospace"}}>
                    #{t.id}
                  </td>
                  <td style={{padding:"11px 14px",fontSize:13,fontWeight:600,color:"#374151"}}>
                    {t.category}
                    {t.description && t.description !== t.category && (
                      <div style={{fontSize:10,color:"#94a3b8",fontWeight:400}}>{t.description}</div>
                    )}
                  </td>
                  <td style={{padding:"11px 14px"}}>
                    <span style={{padding:"3px 9px",borderRadius:20,fontSize:11,fontWeight:700,
                      background:t.type==="recette"?"#dcfce7":"#fee2e2",
                      color:t.type==="recette"?"#166534":"#991b1b"}}>
                      {t.type==="recette"?"▲":"▼"} {t.type}
                    </span>
                  </td>
                  <td style={{padding:"11px 14px",fontSize:12,color:"#6b7280"}}>{t.date}</td>
                  <td style={{padding:"11px 14px",fontSize:12,color:"#6b7280"}}>{t.commune}</td>
                  <td style={{padding:"11px 14px",fontSize:13,fontWeight:800,textAlign:"right",
                    color:t.type==="recette"?"#10b981":"#ef4444"}}>
                    {t.type==="recette"?"+":"-"}{fmt(t.amount)}
                  </td>
                  <td style={{padding:"11px 14px"}}>
                    {t.hash && t.hash.length > 20 ? (
                      <a href={`https://amoy.polygonscan.com/tx/${t.hash}`}
                        target="_blank" rel="noopener noreferrer"
                        style={{color:"#0d9488",fontSize:11,display:"flex",alignItems:"center",gap:4,textDecoration:"none"}}>
                        {t.hash.slice(0,8)}... <ExternalLink size={10}/>
                      </a>
                    ) : (
                      <span style={{fontSize:10,color:"#e2e8f0"}}>local</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Footer totaux */}
        {list.length > 0 && (
          <div style={{background:"#f8fafc",padding:"14px 20px",borderTop:"1px solid #e2e8f0",
            display:"flex",gap:24}}>
            <div>
              <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>
                Recettes affichées
              </div>
              <div style={{fontSize:16,fontWeight:800,color:"#10b981"}}>
                +{fmt(list.filter(t=>t.type==="recette").reduce((s,t)=>s+t.amount,0))}
              </div>
            </div>
            <div>
              <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>
                Dépenses affichées
              </div>
              <div style={{fontSize:16,fontWeight:800,color:"#ef4444"}}>
                -{fmt(list.filter(t=>t.type==="dépense").reduce((s,t)=>s+t.amount,0))}
              </div>
            </div>
            <div style={{marginLeft:"auto"}}>
              <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>Solde</div>
              <div style={{fontSize:16,fontWeight:800,
                color:balance>=0?"#0d9488":"#ef4444"}}>
                {balance>=0?"+":""}{fmt(balance)}
              </div>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}

// ── Root ──────────────────────────────────────────────────────────────────────
const VIEWS = {
  dashboard:            <DashboardView/>,
  "nouvelle-transaction": <NewTransactionView/>,
  registre:             <RegistreView/>,
};

export const FinancialDirectorDashboard = ({onLogout}) => {
  const [view, setView] = useState("dashboard");

  return (
    <div style={{display:"flex",height:"100vh",fontFamily:"'Segoe UI',system-ui,sans-serif",
      background:"#f0f4f8",overflow:"hidden",flexDirection:"column"}}>

      {/* Barre blockchain en haut */}
      <BlockchainBanner/>

      <div style={{display:"flex",flex:1,overflow:"hidden"}}>
        <Sidebar active={view} setActive={setView}/>

        <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
          <header style={{background:"linear-gradient(to right,#0f766e,#0d9488)",padding:"0 28px",
            height:60,display:"flex",alignItems:"center",justifyContent:"space-between",
            boxShadow:"0 2px 10px rgba(0,0,0,.15)",flexShrink:0}}>
            <div style={{display:"flex",alignItems:"center",gap:14}}>
              <div style={{width:40,height:40,background:"#f97316",borderRadius:9,display:"flex",
                alignItems:"center",justifyContent:"center",fontWeight:900,color:"white",fontSize:18}}>B</div>
              <div>
                <div style={{color:"white",fontWeight:800,fontSize:16}}>Budget Ouvert — Directeur Financier</div>
                <div style={{color:"#99f6e4",fontSize:11}}>Commune Cocody · Blockchain Polygon</div>
              </div>
            </div>
            <button onClick={onLogout}
              style={{display:"flex",alignItems:"center",gap:7,padding:"7px 16px",
                background:"rgba(255,255,255,.15)",color:"white",
                border:"1px solid rgba(255,255,255,.2)",borderRadius:8,cursor:"pointer",
                fontSize:13,fontWeight:600}}>
              <LogOut size={15}/> Déconnexion
            </button>
          </header>

          <main style={{flex:1,overflowY:"auto",padding:"24px 28px"}}>
            {VIEWS[view] ?? <DashboardView/>}
          </main>
        </div>
      </div>
    </div>
  );
};

export default FinancialDirectorDashboard;