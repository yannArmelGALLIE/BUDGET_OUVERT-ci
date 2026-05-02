// @ts-nocheck
// src/pages/MayorDashboard.jsx
// Maire : lecture seule des données blockchain
import { useState } from 'react';
import { LogOut, BarChart3, TrendingUp, ExternalLink, RefreshCw } from 'lucide-react';
import { useBlockchain } from '../lib/useBlockchain';
import { BlockchainBanner } from '../components/BlockchainBanner';

const fmt  = n => new Intl.NumberFormat("fr-FR").format(Math.abs(n)) + " FCFA";
const fmtM = n => (Math.abs(n)/1e6).toFixed(1) + " M";

export const MayorDashboard = ({ onLogout }) => {
  const {
    transactions, totalRecettes, totalDepenses, balance,
    loading, mode, refreshTransactions, commune,
  } = useBlockchain();

  const [search,   setSearch]   = useState('');
  const [typeFilter, setType]   = useState('tous');

  const filtered = transactions
    .filter(t => typeFilter === 'tous' || t.type === typeFilter)
    .filter(t =>
      t.category.toLowerCase().includes(search.toLowerCase()) ||
      t.description?.toLowerCase().includes(search.toLowerCase())
    );

  return (
    <div style={{minHeight:"100vh",background:"#f8fafc",fontFamily:"'Segoe UI',system-ui,sans-serif",
      display:"flex",flexDirection:"column"}}>

      <BlockchainBanner/>

      {/* Header */}
      <header style={{background:"linear-gradient(135deg,#0f766e,#0d9488)",
        padding:"16px 32px",display:"flex",alignItems:"center",justifyContent:"space-between",
        boxShadow:"0 4px 12px rgba(0,0,0,.15)"}}>
        <div>
          <h1 style={{color:"white",fontWeight:800,fontSize:22,margin:0}}>
            Budget Ouvert — Maire
          </h1>
          <p style={{color:"#99f6e4",fontSize:12,margin:"4px 0 0"}}>
            {commune} · {mode==="real" ? "Données blockchain en temps réel" : "Mode simulation"}
          </p>
        </div>
        <div style={{display:"flex",gap:10}}>
          <button onClick={refreshTransactions}
            style={{display:"flex",alignItems:"center",gap:6,padding:"8px 16px",
              background:"rgba(255,255,255,.2)",color:"white",border:"1px solid rgba(255,255,255,.3)",
              borderRadius:9,cursor:"pointer",fontSize:13,fontWeight:600}}>
            <RefreshCw size={14}/> Actualiser
          </button>
          <button onClick={onLogout}
            style={{display:"flex",alignItems:"center",gap:6,padding:"8px 16px",
              background:"rgba(255,255,255,.2)",color:"white",border:"1px solid rgba(255,255,255,.3)",
              borderRadius:9,cursor:"pointer",fontSize:13,fontWeight:600}}>
            <LogOut size={14}/> Déconnexion
          </button>
        </div>
      </header>

      <main style={{flex:1,padding:32}}>
        {/* KPIs */}
        <div style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:20,marginBottom:28}}>
          {[
            {label:"Total Recettes",  value:fmtM(totalRecettes), sub:`${transactions.filter(t=>t.type==="recette").length} transactions`, color:"#10b981",bg:"#f0fdf4",icon:<TrendingUp size={24}/>},
            {label:"Total Dépenses",  value:fmtM(totalDepenses), sub:`${transactions.filter(t=>t.type==="dépense").length} transactions`, color:"#ef4444",bg:"#fef2f2",icon:<BarChart3 size={24}/>},
            {label:"Solde Net",       value:fmtM(balance),       sub:`${balance>=0?"Excédent":"Déficit"} communal`, color:balance>=0?"#0d9488":"#ef4444",bg:balance>=0?"#f0fdfa":"#fef2f2",icon:<BarChart3 size={24}/>},
          ].map((k,i)=>(
            <div key={i} style={{background:k.bg,borderRadius:16,padding:"22px 24px",
              border:"1px solid #e2e8f0",boxShadow:"0 2px 8px rgba(0,0,0,.04)"}}>
              <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12}}>
                <span style={{fontSize:12,color:"#6b7280",fontWeight:600,textTransform:"uppercase",letterSpacing:".05em"}}>
                  {k.label}
                </span>
                <div style={{color:k.color}}>{k.icon}</div>
              </div>
              <div style={{fontSize:26,fontWeight:900,color:k.color}}>{k.value}</div>
              <div style={{fontSize:11,color:"#94a3b8",marginTop:6}}>{k.sub}</div>
            </div>
          ))}
        </div>

        {/* Filtres */}
        <div style={{display:"flex",gap:10,marginBottom:16,alignItems:"center"}}>
          <div style={{display:"flex",gap:6}}>
            {[
              {id:"tous",    label:"Toutes"},
              {id:"recette", label:"▲ Recettes"},
              {id:"dépense", label:"▼ Dépenses"},
            ].map(f => (
              <button key={f.id} onClick={()=>setType(f.id)}
                style={{padding:"7px 18px",borderRadius:20,border:"1px solid #e2e8f0",cursor:"pointer",
                  fontSize:12,fontWeight:600,
                  background:typeFilter===f.id?"#134e4a":"white",
                  color:typeFilter===f.id?"white":"#374151",transition:"all .15s"}}>
                {f.label}
              </button>
            ))}
          </div>
          <input value={search} onChange={e=>setSearch(e.target.value)}
            placeholder="Rechercher une transaction..."
            style={{marginLeft:"auto",padding:"8px 16px",borderRadius:10,
              border:"1px solid #e2e8f0",fontSize:13,outline:"none",width:260}}/>
        </div>

        {/* Table */}
        <div style={{background:"white",borderRadius:16,border:"1px solid #e2e8f0",
          overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,.04)"}}>
          <div style={{padding:"16px 24px",borderBottom:"1px solid #f1f5f9",
            display:"flex",alignItems:"center",justifyContent:"space-between"}}>
            <div>
              <h2 style={{fontSize:16,fontWeight:700,color:"#134e4a",margin:0}}>
                Détail des Transactions — {commune}
              </h2>
              <p style={{fontSize:12,color:"#94a3b8",margin:"4px 0 0"}}>
                {filtered.length} résultat{filtered.length>1?"s":""} ·{" "}
                {mode==="real" ? "⛓ Données immuables sur Polygon" : "⚡ Simulation locale"}
              </p>
            </div>
          </div>

          {loading && (
            <div style={{padding:40,textAlign:"center",color:"#94a3b8",fontSize:13}}>
              Chargement des données blockchain...
            </div>
          )}

          {!loading && filtered.length === 0 && (
            <div style={{padding:40,textAlign:"center",color:"#94a3b8",fontSize:13}}>
              Aucune transaction à afficher
            </div>
          )}

          {filtered.length > 0 && (
            <div style={{overflowX:"auto"}}>
              <table style={{width:"100%",borderCollapse:"collapse"}}>
                <thead style={{background:"#f8fafc",borderBottom:"2px solid #e2e8f0"}}>
                  <tr>
                    {["Date","Description","Catégorie","Type","Montant (FCFA)","Preuve blockchain"].map(h=>(
                      <th key={h} style={{padding:"11px 16px",textAlign:"left",fontSize:11,
                        fontWeight:700,color:"#6b7280",textTransform:"uppercase",letterSpacing:".04em"}}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((t,i)=>(
                    <tr key={t.id} style={{borderBottom:"1px solid #f1f5f9",
                      background:i%2===0?"white":"#fafafa",
                      transition:"background .1s"}}>
                      <td style={{padding:"12px 16px",fontSize:12,color:"#6b7280"}}>{t.date}</td>
                      <td style={{padding:"12px 16px",fontSize:13,fontWeight:600,color:"#374151"}}>
                        {t.description || t.category}
                      </td>
                      <td style={{padding:"12px 16px"}}>
                        <span style={{padding:"3px 10px",background:"#f0fdfa",color:"#0d9488",
                          borderRadius:20,fontSize:11,fontWeight:600}}>
                          {t.category}
                        </span>
                      </td>
                      <td style={{padding:"12px 16px"}}>
                        <span style={{padding:"3px 10px",borderRadius:20,fontSize:11,fontWeight:700,
                          background:t.type==="recette"?"#dcfce7":"#fee2e2",
                          color:t.type==="recette"?"#166534":"#991b1b"}}>
                          {t.type==="recette"?"▲ Recette":"▼ Dépense"}
                        </span>
                      </td>
                      <td style={{padding:"12px 16px",fontSize:13,fontWeight:800,textAlign:"right",
                        color:t.type==="recette"?"#10b981":"#ef4444"}}>
                        {t.type==="recette"?"+":"-"}{fmt(t.amount)}
                      </td>
                      <td style={{padding:"12px 16px"}}>
                        {t.hash && t.hash.length > 20 ? (
                          <a href={`https://amoy.polygonscan.com/tx/${t.hash}`}
                            target="_blank" rel="noopener noreferrer"
                            style={{color:"#0d9488",fontSize:11,display:"flex",
                              alignItems:"center",gap:4,textDecoration:"none",fontFamily:"monospace"}}>
                            {t.hash.slice(0,10)}... <ExternalLink size={10}/>
                          </a>
                        ) : (
                          <span style={{fontSize:11,color:"#e2e8f0",fontStyle:"italic"}}>simulation</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Footer */}
              <div style={{background:"#f8fafc",padding:"14px 24px",borderTop:"2px solid #e2e8f0",
                display:"flex",gap:32,alignItems:"center"}}>
                <div>
                  <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>Recettes</div>
                  <div style={{fontSize:15,fontWeight:800,color:"#10b981"}}>
                    +{fmt(filtered.filter(t=>t.type==="recette").reduce((s,t)=>s+t.amount,0))}
                  </div>
                </div>
                <div>
                  <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>Dépenses</div>
                  <div style={{fontSize:15,fontWeight:800,color:"#ef4444"}}>
                    -{fmt(filtered.filter(t=>t.type==="dépense").reduce((s,t)=>s+t.amount,0))}
                  </div>
                </div>
                <div style={{marginLeft:"auto"}}>
                  <div style={{fontSize:10,color:"#6b7280",fontWeight:600,textTransform:"uppercase"}}>Solde net</div>
                  <div style={{fontSize:15,fontWeight:800,color:balance>=0?"#0d9488":"#ef4444"}}>
                    {balance>=0?"+":""}{fmt(balance)}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
};