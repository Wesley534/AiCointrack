import { useState } from "react";

const screens = {
  onboarding: [
    { id: "splash", label: "Splash / Welcome" },
    { id: "onboarding1", label: "Onboarding – Auto Logging" },
    { id: "onboarding2", label: "Onboarding – Base Sync" },
    { id: "register", label: "Register" },
    { id: "login", label: "Login" },
    { id: "setup1", label: "Setup – Monthly Income" },
    { id: "setup2", label: "Setup – Budget Allocation" },
    { id: "setup3", label: "Setup – Savings Goal" },
  ],
  main: [
    { id: "dashboard", label: "Dashboard" },
    { id: "budget", label: "Budget Overview" },
    { id: "category", label: "Category Detail" },
    { id: "transactions", label: "Transactions" },
    { id: "addtx", label: "Add Transaction" },
    { id: "shopping", label: "Shopping Lists" },
    { id: "shoppingdetail", label: "Shopping List Detail" },
    { id: "savings", label: "Savings Goals" },
    { id: "closeout", label: "Month Closeout" },
    { id: "settings", label: "Settings" },
    { id: "miniapp", label: "Base Miniapp View" },
  ],
};

const allScreens = [...screens.onboarding, ...screens.main];

const palette = {
  bg: "#0A0D12",
  surface: "#111620",
  card: "#161C28",
  border: "#1E2A3A",
  accent: "#00E5A0",
  accentDim: "#00A372",
  purple: "#7C6AFA",
  warning: "#F59E0B",
  danger: "#EF4444",
  text: "#E8EDF5",
  muted: "#6B7A90",
};

const css = `
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: ${palette.bg}; font-family: 'DM Sans', sans-serif; color: ${palette.text}; }
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: ${palette.surface}; }
  ::-webkit-scrollbar-thumb { background: ${palette.border}; border-radius: 4px; }
  .screen-phone { 
    width: 375px; min-height: 720px; background: ${palette.surface}; 
    border-radius: 40px; overflow: hidden; position: relative;
    border: 1.5px solid ${palette.border};
    box-shadow: 0 40px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.04);
  }
  .status-bar {
    display: flex; justify-content: space-between; align-items: center;
    padding: 12px 24px 8px; font-size: 11px; color: ${palette.muted};
    font-family: 'Syne', sans-serif; font-weight: 600;
  }
  .pill { background: ${palette.card}; border: 1px solid ${palette.border}; border-radius: 999px; padding: 3px 10px; font-size: 11px; color: ${palette.muted}; }
  .pill-green { background: rgba(0,229,160,0.1); border: 1px solid rgba(0,229,160,0.3); color: ${palette.accent}; }
  .pill-warn { background: rgba(245,158,11,0.1); border: 1px solid rgba(245,158,11,0.3); color: ${palette.warning}; }
  .pill-red { background: rgba(239,68,68,0.1); border: 1px solid rgba(239,68,68,0.3); color: ${palette.danger}; }
  .btn-primary { 
    background: ${palette.accent}; color: #000; font-family: 'Syne', sans-serif; font-weight: 700;
    border: none; border-radius: 14px; padding: 14px 28px; cursor: pointer; font-size: 14px;
    width: 100%; transition: opacity 0.15s;
  }
  .btn-ghost { 
    background: transparent; color: ${palette.muted}; font-family: 'DM Sans', sans-serif;
    border: 1px solid ${palette.border}; border-radius: 14px; padding: 12px 28px; cursor: pointer; font-size: 13px;
    width: 100%;
  }
  .input-field {
    background: ${palette.card}; border: 1px solid ${palette.border}; border-radius: 12px;
    padding: 12px 16px; color: ${palette.text}; font-family: 'DM Sans', sans-serif; font-size: 14px;
    width: 100%; outline: none;
  }
  .input-label { font-size: 11px; color: ${palette.muted}; margin-bottom: 6px; font-family: 'Syne', sans-serif; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; }
  .section-title { font-family: 'Syne', sans-serif; font-weight: 700; font-size: 16px; color: ${palette.text}; }
  .nav-bar {
    position: absolute; bottom: 0; left: 0; right: 0;
    background: ${palette.card}; border-top: 1px solid ${palette.border};
    display: flex; justify-content: space-around; padding: 10px 0 20px;
  }
  .nav-item { display: flex; flex-direction: column; align-items: center; gap: 3px; font-size: 9px; color: ${palette.muted}; cursor: pointer; }
  .nav-item.active { color: ${palette.accent}; }
  .progress-bar { background: ${palette.border}; border-radius: 999px; height: 6px; overflow: hidden; }
  .progress-fill { height: 100%; border-radius: 999px; background: ${palette.accent}; transition: width 0.3s; }
  .variance-green { color: ${palette.accent}; }
  .variance-red { color: ${palette.danger}; }
  .card-block { background: ${palette.card}; border: 1px solid ${palette.border}; border-radius: 16px; padding: 16px; }
  .tag { font-size: 10px; font-family: 'Syne', sans-serif; font-weight: 600; padding: 2px 8px; border-radius: 99px; }
  .tag-need { background: rgba(124,106,250,0.15); color: ${palette.purple}; border: 1px solid rgba(124,106,250,0.3); }
  .tag-want { background: rgba(245,158,11,0.12); color: ${palette.warning}; border: 1px solid rgba(245,158,11,0.3); }
  .tag-save { background: rgba(0,229,160,0.1); color: ${palette.accent}; border: 1px solid rgba(0,229,160,0.25); }
  .chain-badge {
    background: rgba(0,229,160,0.08); border: 1px solid rgba(0,229,160,0.2);
    border-radius: 8px; padding: 8px 12px; display: flex; align-items: center; gap: 8px; font-size: 12px;
  }
  .divider { height: 1px; background: ${palette.border}; margin: 12px 0; }
`;

// ─── INDIVIDUAL SCREEN RENDERERS ─────────────────────────────────────────────

function Splash() {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100%", padding: "40px 32px", gap: 24 }}>
      <div style={{ width: 80, height: 80, borderRadius: 24, background: "linear-gradient(135deg, #00E5A0 0%, #7C6AFA 100%)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 36 }}>💰</div>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 32, color: palette.text, letterSpacing: "-0.02em" }}>CoinTrack</div>
        <div style={{ color: palette.muted, fontSize: 14, marginTop: 8, lineHeight: 1.5 }}>Your AI-powered money companion — tracks every shilling, automatically.</div>
      </div>
      <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 10, marginTop: 16 }}>
        <button className="btn-primary">Get Started</button>
        <button className="btn-ghost">I already have an account</button>
      </div>
      <div style={{ marginTop: 8 }}>
        <div className="chain-badge">
          <span style={{ width: 8, height: 8, borderRadius: "50%", background: palette.accent, display: "inline-block" }}></span>
          <span style={{ color: palette.muted, fontSize: 11 }}>Powered by <strong style={{ color: palette.accent }}>Base</strong> — your money lives onchain</span>
        </div>
      </div>
    </div>
  );
}

function Onboarding1() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column" }}>
      <div style={{ display: "flex", gap: 6, marginBottom: 40 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i === 1 ? palette.accent : palette.border }}></div>)}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 48, marginBottom: 20 }}>🔔</div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, lineHeight: 1.2, marginBottom: 12 }}>Never log expenses manually again</div>
        <div style={{ color: palette.muted, fontSize: 14, lineHeight: 1.6, marginBottom: 24 }}>CoinTrack reads your M-Pesa, email, and notification alerts to auto-log transactions the moment they happen.</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {["📱 M-Pesa & SMS auto-detection", "📧 MiniSend email notification parsing", "⛓️ Base blockchain transaction sync", "🤖 AI categorizes every transaction"].map(f => (
            <div key={f} className="card-block" style={{ fontSize: 13, display: "flex", alignItems: "center", gap: 10 }}>{f}</div>
          ))}
        </div>
      </div>
      <button className="btn-primary" style={{ marginTop: 24 }}>Next →</button>
    </div>
  );
}

function Onboarding2() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column" }}>
      <div style={{ display: "flex", gap: 6, marginBottom: 40 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i <= 2 ? palette.accent : palette.border }}></div>)}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 48, marginBottom: 20 }}>⛓️</div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, lineHeight: 1.2, marginBottom: 12 }}>Your transactions, stored on Base</div>
        <div style={{ color: palette.muted, fontSize: 14, lineHeight: 1.6, marginBottom: 24 }}>Every expense you log is recorded onchain — transparent, verifiable, and yours forever. No bank can block it.</div>
        <div className="card-block" style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, color: palette.muted, marginBottom: 6, fontFamily: "Syne", fontWeight: 600 }}>LATEST ON-CHAIN ACTIVITY</div>
          {[{ desc: "Groceries – Carrefour", amt: "-Ksh 2,400", cat: "🛒 Food", type: "need" }, { desc: "Received – MiniSend", amt: "+Ksh 5,000", cat: "💸 Income", type: "save" }].map(t => (
            <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderBottom: `1px solid ${palette.border}` }}>
              <div>
                <div style={{ fontSize: 13, color: palette.text }}>{t.desc}</div>
                <div style={{ fontSize: 11, color: palette.muted }}>{t.cat}</div>
              </div>
              <div style={{ fontSize: 13, color: t.amt.startsWith("+") ? palette.accent : palette.danger, fontFamily: "Syne", fontWeight: 700 }}>{t.amt}</div>
            </div>
          ))}
        </div>
        <div className="chain-badge">
          <span>🔷</span>
          <span style={{ color: palette.muted, fontSize: 11 }}>Stored on <strong style={{ color: palette.accent }}>Base L2</strong> — fast, cheap, secure</span>
        </div>
      </div>
      <button className="btn-primary" style={{ marginTop: 24 }}>Let's set up your budget →</button>
    </div>
  );
}

function Register() {
  return (
    <div style={{ padding: "40px 28px", display: "flex", flexDirection: "column", gap: 20 }}>
      <div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, marginBottom: 6 }}>Create account</div>
        <div style={{ color: palette.muted, fontSize: 13 }}>Start managing your money smarter</div>
      </div>
      {[["Full Name", "John Doe"], ["Email", "john@example.com"], ["Password", "••••••••"]].map(([label, ph]) => (
        <div key={label}>
          <div className="input-label">{label}</div>
          <input className="input-field" placeholder={ph} readOnly />
        </div>
      ))}
      <button className="btn-primary">Create Account</button>
      <div style={{ textAlign: "center", color: palette.muted, fontSize: 12 }}>— or sign up with —</div>
      <button className="btn-ghost">🔵 Continue with Base Wallet</button>
      <div style={{ textAlign: "center", color: palette.muted, fontSize: 12 }}>Already have an account? <span style={{ color: palette.accent }}>Log in</span></div>
    </div>
  );
}

function Login() {
  return (
    <div style={{ padding: "40px 28px", display: "flex", flexDirection: "column", gap: 20, height: "100%", justifyContent: "center" }}>
      <div>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 26, marginBottom: 6 }}>Welcome back 👋</div>
        <div style={{ color: palette.muted, fontSize: 13 }}>Log back into your CoinTrack</div>
      </div>
      {[["Email", "john@example.com"], ["Password", "••••••••"]].map(([label, ph]) => (
        <div key={label}>
          <div className="input-label">{label}</div>
          <input className="input-field" placeholder={ph} readOnly />
        </div>
      ))}
      <button className="btn-primary">Log In</button>
      <button className="btn-ghost">🔵 Log in with Base Wallet</button>
      <div style={{ textAlign: "center", color: palette.muted, fontSize: 12 }}><span style={{ color: palette.accent }}>Forgot password?</span></div>
    </div>
  );
}

function Setup1() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column" }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i === 1 ? palette.accent : palette.border }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 6 }}>Step 1: Monthly Income</div>
      <div style={{ color: palette.muted, fontSize: 13, marginBottom: 28 }}>Tell us how much you earn each month so we can build your budget.</div>
      <div>
        <div className="input-label">Monthly Income (Ksh)</div>
        <div style={{ background: palette.card, border: `1.5px solid ${palette.accent}`, borderRadius: 12, padding: "14px 16px", display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ color: palette.muted }}>Ksh</span>
          <input style={{ background: "none", border: "none", color: palette.text, fontSize: 22, fontFamily: "Syne", fontWeight: 700, outline: "none", flex: 1 }} defaultValue="85,000" readOnly />
        </div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 20 }}>
        <div className="card-block" style={{ display: "flex", justifyContent: "space-between" }}>
          <span style={{ color: palette.muted, fontSize: 13 }}>Salary</span>
          <span style={{ color: palette.accent, fontFamily: "Syne", fontWeight: 700 }}>Ksh 85,000</span>
        </div>
        <button style={{ background: "none", border: `1px dashed ${palette.border}`, borderRadius: 12, padding: 12, color: palette.muted, fontSize: 13, cursor: "pointer" }}>+ Add another income source</button>
      </div>
      <button className="btn-primary" style={{ marginTop: "auto" }}>Next →</button>
    </div>
  );
}

function Setup2() {
  const cats = [["🍔 Food", 20, "need"], ["🏠 Rent", 35, "need"], ["🚗 Transport", 10, "need"], ["🎉 Entertainment", 15, "want"], ["💰 Savings", 20, "save"]];
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column", overflow: "auto" }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: i <= 2 ? palette.accent : palette.border }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 6 }}>Step 2: Budget Allocation</div>
      <div style={{ color: palette.muted, fontSize: 13, marginBottom: 16 }}>We've applied 50/30/20 rule. Adjust as needed.</div>
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <button className="pill pill-green" style={{ cursor: "pointer" }}>50/30/20</button>
        <button className="pill" style={{ cursor: "pointer" }}>Manual</button>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {cats.map(([cat, pct, type]) => (
          <div key={cat} className="card-block" style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                <span style={{ fontSize: 13 }}>{cat}</span>
                <span className={`tag tag-${type}`}>{type}</span>
              </div>
              <div className="progress-bar"><div className="progress-fill" style={{ width: `${pct}%` }}></div></div>
            </div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14, minWidth: 36, textAlign: "right" }}>{pct}%</div>
          </div>
        ))}
      </div>
      <button className="btn-primary" style={{ marginTop: 16 }}>Next →</button>
    </div>
  );
}

function Setup3() {
  return (
    <div style={{ padding: "40px 28px", height: "100%", display: "flex", flexDirection: "column" }}>
      <div style={{ marginBottom: 12, display: "flex", gap: 6 }}>
        {[1, 2, 3].map(i => <div key={i} style={{ height: 3, flex: 1, borderRadius: 99, background: palette.accent }}></div>)}
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, marginBottom: 6 }}>Step 3: Savings Goal 🎯</div>
      <div style={{ color: palette.muted, fontSize: 13, marginBottom: 28 }}>What are you saving towards?</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {[["Emergency Fund", "6 months expenses", "🛡️"], ["Vacation", "Trip to Mombasa", "✈️"], ["New Laptop", "MacBook Pro", "💻"]].map(([name, desc, icon]) => (
          <div key={name} className="card-block" style={{ display: "flex", alignItems: "center", gap: 12, cursor: "pointer", border: name === "Emergency Fund" ? `1.5px solid ${palette.accent}` : `1px solid ${palette.border}` }}>
            <span style={{ fontSize: 24 }}>{icon}</span>
            <div>
              <div style={{ fontSize: 14, fontFamily: "Syne", fontWeight: 600 }}>{name}</div>
              <div style={{ fontSize: 12, color: palette.muted }}>{desc}</div>
            </div>
            {name === "Emergency Fund" && <span className="pill pill-green" style={{ marginLeft: "auto" }}>Selected</span>}
          </div>
        ))}
        <button style={{ background: "none", border: `1px dashed ${palette.border}`, borderRadius: 12, padding: 12, color: palette.muted, fontSize: 13, cursor: "pointer" }}>+ Create custom goal</button>
      </div>
      <button className="btn-primary" style={{ marginTop: "auto" }}>Go to Dashboard →</button>
    </div>
  );
}

function Dashboard() {
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div>
            <div style={{ color: palette.muted, fontSize: 12 }}>Good morning,</div>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20 }}>John Kamau 👋</div>
          </div>
          <div style={{ width: 40, height: 40, borderRadius: "50%", background: `linear-gradient(135deg, ${palette.accent}, ${palette.purple})`, display: "flex", alignItems: "center", justifyContent: "center", color: "#000", fontFamily: "Syne", fontWeight: 800, fontSize: 16 }}>J</div>
        </div>
        {/* Balance Card */}
        <div style={{ background: `linear-gradient(135deg, ${palette.purple}22, ${palette.accent}11)`, border: `1px solid ${palette.purple}44`, borderRadius: 20, padding: "20px", marginBottom: 16 }}>
          <div style={{ fontSize: 12, color: palette.muted, marginBottom: 4 }}>FREE TO SPEND</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 34, marginBottom: 4 }}>Ksh 24,500</div>
          <div style={{ display: "flex", gap: 8 }}>
            <span className="pill pill-green">+Ksh 2,300 vs last month</span>
          </div>
          <div style={{ marginTop: 14 }}>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: palette.muted, marginBottom: 6 }}>
              <span>Month progress</span><span>March 8 / 31</span>
            </div>
            <div className="progress-bar"><div className="progress-fill" style={{ width: "26%" }}></div></div>
          </div>
        </div>
        {/* Quick Stats */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 16 }}>
          {[["Total Budget", "Ksh 85,000", ""], ["Spent So Far", "Ksh 60,500", "variance-red"], ["Saved", "Ksh 17,000", "variance-green"], ["Shopping", "3 lists", ""]].map(([label, val, cls]) => (
            <div key={label} className="card-block">
              <div style={{ fontSize: 11, color: palette.muted, marginBottom: 4 }}>{label}</div>
              <div className={`${cls}`} style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 16 }}>{val}</div>
            </div>
          ))}
        </div>
        {/* AI Insight */}
        <div style={{ background: "rgba(124,106,250,0.08)", border: `1px solid rgba(124,106,250,0.25)`, borderRadius: 16, padding: 14, marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: palette.purple, fontFamily: "Syne", fontWeight: 600, marginBottom: 6 }}>🤖 AI INSIGHT</div>
          <div style={{ fontSize: 13, lineHeight: 1.5 }}>You're on track this month! Food spending is <span style={{ color: palette.warning }}>18% over budget</span>. Reduce dining out by Ksh 800 to stay in the green.</div>
        </div>
        {/* Recent Transactions */}
        <div className="section-title" style={{ marginBottom: 10 }}>Recent Transactions</div>
        {[{ desc: "Uber – CBD to Westlands", cat: "🚗 Transport", amt: "-Ksh 350", source: "auto" }, { desc: "Quickmart Supermarket", cat: "🛒 Food", amt: "-Ksh 1,840", source: "auto" }, { desc: "MiniSend – Received", cat: "💸 Income", amt: "+Ksh 5,000", source: "chain" }].map(t => (
          <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${palette.border}` }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: palette.card, border: `1px solid ${palette.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>{t.cat.split(" ")[0]}</div>
              <div>
                <div style={{ fontSize: 13 }}>{t.desc}</div>
                <div style={{ fontSize: 11, color: palette.muted, display: "flex", gap: 6 }}>
                  {t.cat.split(" ").slice(1).join(" ")}
                  {t.source === "auto" && <span className="pill" style={{ fontSize: 9 }}>Auto-logged</span>}
                  {t.source === "chain" && <span className="pill pill-green" style={{ fontSize: 9 }}>Onchain</span>}
                </div>
              </div>
            </div>
            <div style={{ fontSize: 13, color: t.amt.startsWith("+") ? palette.accent : palette.danger, fontFamily: "Syne", fontWeight: 700 }}>{t.amt}</div>
          </div>
        ))}
      </div>
      <NavBar active="home" />
    </div>
  );
}

function BudgetPage() {
  const cats = [["🍔 Food", 20000, 23600, "need"], ["🏠 Rent", 30000, 30000, "need"], ["🚗 Transport", 8000, 5200, "need"], ["🎉 Entertainment", 12750, 9000, "want"], ["💰 Savings", 17000, 17000, "save"]];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div className="section-title" style={{ fontSize: 20 }}>Budget — March 2025</div>
          <button className="pill">+ Category</button>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 16, textAlign: "center" }}>
          {[["Planned", "Ksh 87,750", palette.muted], ["Actual", "Ksh 84,800", palette.warning], ["Remaining", "Ksh 2,950", palette.accent]].map(([l, v, c]) => (
            <div key={l} className="card-block">
              <div style={{ fontSize: 10, color: palette.muted, marginBottom: 4 }}>{l}</div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: c }}>{v}</div>
            </div>
          ))}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {cats.map(([cat, planned, actual, type]) => {
            const pct = Math.min(100, Math.round((actual / planned) * 100));
            const over = actual > planned;
            return (
              <div key={cat} className="card-block" style={{ border: over ? `1px solid rgba(239,68,68,0.3)` : `1px solid ${palette.border}` }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                  <span style={{ fontSize: 14 }}>{cat}</span>
                  <span className={`tag tag-${type}`}>{type}</span>
                </div>
                <div className="progress-bar" style={{ marginBottom: 8 }}>
                  <div className="progress-fill" style={{ width: `${pct}%`, background: over ? palette.danger : palette.accent }}></div>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
                  <span style={{ color: palette.muted }}>Planned: Ksh {planned.toLocaleString()}</span>
                  <span style={{ color: over ? palette.danger : palette.accent }}>Actual: Ksh {actual.toLocaleString()}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <NavBar active="budget" />
    </div>
  );
}

function CategoryDetail() {
  const txs = [
    { desc: "KFC Westlands", amt: 1200, date: "Mar 6" }, { desc: "Java House", amt: 850, date: "Mar 4" },
    { desc: "Carrefour Groceries", amt: 3200, date: "Mar 2" }, { desc: "Pizza Inn", amt: 1400, date: "Mar 1" }
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 20 }}>
          <button style={{ background: "none", border: "none", color: palette.muted, fontSize: 18, cursor: "pointer" }}>←</button>
          <div className="section-title" style={{ fontSize: 20 }}>🍔 Food</div>
          <span className="tag tag-need" style={{ marginLeft: "auto" }}>need</span>
        </div>
        <div style={{ background: `linear-gradient(135deg, rgba(239,68,68,0.12), rgba(239,68,68,0.04))`, border: `1px solid rgba(239,68,68,0.2)`, borderRadius: 20, padding: 20, marginBottom: 16, textAlign: "center" }}>
          <div style={{ fontSize: 12, color: palette.muted, marginBottom: 4 }}>OVER BUDGET BY</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 28, color: palette.danger, marginBottom: 4 }}>Ksh 3,600</div>
          <div style={{ fontSize: 12, color: palette.muted }}>Ksh 23,600 spent of Ksh 20,000 planned</div>
          <div className="progress-bar" style={{ marginTop: 14 }}>
            <div className="progress-fill" style={{ width: "100%", background: palette.danger }}></div>
          </div>
        </div>
        <div className="section-title" style={{ marginBottom: 10, fontSize: 14 }}>Transactions this month</div>
        {txs.map(t => (
          <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: `1px solid ${palette.border}` }}>
            <div>
              <div style={{ fontSize: 13 }}>{t.desc}</div>
              <div style={{ fontSize: 11, color: palette.muted }}>{t.date}</div>
            </div>
            <div style={{ color: palette.danger, fontFamily: "Syne", fontWeight: 700, fontSize: 13 }}>-Ksh {t.amt.toLocaleString()}</div>
          </div>
        ))}
      </div>
      <NavBar active="budget" />
    </div>
  );
}

function Transactions() {
  const txs = [
    { desc: "Uber – CBD to Westlands", cat: "🚗 Transport", amt: "-350", date: "Mar 8", src: "auto" },
    { desc: "MiniSend – Jane", cat: "💸 Income", amt: "+5,000", date: "Mar 7", src: "chain" },
    { desc: "Quickmart", cat: "🛒 Food", amt: "-1,840", date: "Mar 7", src: "auto" },
    { desc: "Netflix", cat: "🎬 Entertainment", amt: "-1,100", date: "Mar 5", src: "manual" },
    { desc: "Rent – March", cat: "🏠 Rent", amt: "-30,000", date: "Mar 1", src: "manual" },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div className="section-title" style={{ fontSize: 20 }}>Transactions</div>
          <button className="pill pill-green">+ Add</button>
        </div>
        <div style={{ display: "flex", gap: 8, marginBottom: 16, overflowX: "auto" }}>
          {["All", "Auto-logged", "Onchain", "Manual"].map(f => (
            <button key={f} className={f === "All" ? "pill pill-green" : "pill"} style={{ whiteSpace: "nowrap", cursor: "pointer" }}>{f}</button>
          ))}
        </div>
        {txs.map(t => (
          <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 0", borderBottom: `1px solid ${palette.border}` }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: palette.card, border: `1px solid ${palette.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>{t.cat.split(" ")[0]}</div>
              <div>
                <div style={{ fontSize: 13 }}>{t.desc}</div>
                <div style={{ display: "flex", gap: 5, alignItems: "center" }}>
                  <span style={{ fontSize: 11, color: palette.muted }}>{t.date}</span>
                  {t.src === "auto" && <span className="pill" style={{ fontSize: 9 }}>Auto</span>}
                  {t.src === "chain" && <span className="pill pill-green" style={{ fontSize: 9 }}>Onchain</span>}
                  {t.src === "manual" && <span className="pill" style={{ fontSize: 9 }}>Manual</span>}
                </div>
              </div>
            </div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: t.amt.startsWith("+") ? palette.accent : palette.danger }}>Ksh {t.amt}</div>
          </div>
        ))}
      </div>
      <NavBar active="tx" />
    </div>
  );
}

function AddTransaction() {
  return (
    <div style={{ padding: "20px 20px 0", height: "100%", overflow: "auto" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 24 }}>
        <button style={{ background: "none", border: "none", color: palette.muted, fontSize: 18, cursor: "pointer" }}>←</button>
        <div className="section-title" style={{ fontSize: 20 }}>Add Transaction</div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div>
          <div className="input-label">Amount (Ksh)</div>
          <div style={{ background: palette.card, border: `1.5px solid ${palette.accent}`, borderRadius: 12, padding: "14px 16px", display: "flex", gap: 8 }}>
            <span style={{ color: palette.muted }}>Ksh</span>
            <span style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 22 }}>1,200</span>
          </div>
        </div>
        <div>
          <div className="input-label">Description</div>
          <input className="input-field" defaultValue="KFC Westlands" readOnly />
        </div>
        <div>
          <div className="input-label">AI Category Suggestion</div>
          <div style={{ background: "rgba(124,106,250,0.08)", border: `1px solid rgba(124,106,250,0.3)`, borderRadius: 12, padding: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 13 }}>🍔 Food — Want</div>
              <div style={{ fontSize: 11, color: palette.purple }}>AI confidence: 94%</div>
            </div>
            <button className="pill pill-green">Accept</button>
          </div>
        </div>
        <div>
          <div className="input-label">Date</div>
          <input className="input-field" defaultValue="March 8, 2025" readOnly />
        </div>
        <div>
          <div className="input-label">Notes (optional)</div>
          <input className="input-field" placeholder="e.g. Team lunch" readOnly />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 0" }}>
          <div style={{ width: 20, height: 20, borderRadius: 5, border: `2px solid ${palette.accent}`, background: "rgba(0,229,160,0.15)" }}></div>
          <span style={{ fontSize: 13, color: palette.muted }}>Save on Base blockchain</span>
        </div>
        <button className="btn-primary">Log Expense</button>
      </div>
    </div>
  );
}

function ShoppingLists() {
  const lists = [
    { name: "Weekly Groceries", total: 3400, budget: 4000, items: 8, status: "green" },
    { name: "Electronics", total: 48000, budget: 40000, items: 3, status: "red" },
    { name: "Household", total: 1800, budget: 2000, items: 5, status: "yellow" },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div className="section-title" style={{ fontSize: 20 }}>Shopping Lists</div>
          <button className="pill pill-green">+ New List</button>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {lists.map(l => {
            const pct = Math.min(100, Math.round((l.total / l.budget) * 100));
            return (
              <div key={l.name} className="card-block" style={{ border: l.status === "red" ? `1px solid rgba(239,68,68,0.3)` : l.status === "yellow" ? `1px solid rgba(245,158,11,0.3)` : `1px solid ${palette.border}` }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                  <div className="section-title" style={{ fontSize: 14 }}>{l.name}</div>
                  <span className={`pill pill-${l.status === "green" ? "green" : l.status === "red" ? "red" : "warn"}`}>{l.items} items</span>
                </div>
                <div className="progress-bar" style={{ marginBottom: 8 }}>
                  <div className="progress-fill" style={{ width: `${pct}%`, background: l.status === "red" ? palette.danger : l.status === "yellow" ? palette.warning : palette.accent }}></div>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
                  <span style={{ color: palette.muted }}>Est. Ksh {l.total.toLocaleString()}</span>
                  <span style={{ color: palette.muted }}>Budget: Ksh {l.budget.toLocaleString()}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <NavBar active="shop" />
    </div>
  );
}

function ShoppingDetail() {
  const items = [
    { name: "Rice 5kg", qty: 1, price: 500 }, { name: "Milk x6", qty: 2, price: 200 },
    { name: "Bread", qty: 1, price: 120 }, { name: "Chicken", qty: 1, price: 650 },
    { name: "Tomatoes 1kg", qty: 2, price: 150 },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
          <button style={{ background: "none", border: "none", color: palette.muted, fontSize: 18 }}>←</button>
          <div className="section-title" style={{ fontSize: 20 }}>Weekly Groceries</div>
        </div>
        <div style={{ marginLeft: 28, marginBottom: 16 }}>
          <span className="tag tag-need">Linked: Food budget</span>
        </div>
        <div className="card-block" style={{ marginBottom: 16, display: "flex", justifyContent: "space-between" }}>
          <div><div style={{ fontSize: 11, color: palette.muted }}>TOTAL ESTIMATED</div><div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 20 }}>Ksh 1,820</div></div>
          <div style={{ textAlign: "right" }}><div style={{ fontSize: 11, color: palette.muted }}>BUDGET REMAINING</div><div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 20, color: palette.accent }}>Ksh 2,180</div></div>
        </div>
        {items.map(i => (
          <div key={i.name} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${palette.border}` }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: palette.card, border: `1px solid ${palette.border}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12 }}>☐</div>
              <div>
                <div style={{ fontSize: 13 }}>{i.name}</div>
                <div style={{ fontSize: 11, color: palette.muted }}>Qty: {i.qty}</div>
              </div>
            </div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13 }}>Ksh {i.price}</div>
          </div>
        ))}
        <button className="btn-primary" style={{ marginTop: 20 }}>✓ Checkout → Log as Expenses</button>
      </div>
      <NavBar active="shop" />
    </div>
  );
}

function Savings() {
  const goals = [
    { name: "Emergency Fund 🛡️", saved: 34000, target: 100000, monthly: 5000 },
    { name: "Vacation ✈️", saved: 12000, target: 50000, monthly: 3000 },
    { name: "Laptop 💻", saved: 8000, target: 120000, monthly: 10000 },
  ];
  return (
    <div style={{ height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div className="section-title" style={{ fontSize: 20 }}>Savings Goals</div>
          <button className="pill pill-green">+ New Goal</button>
        </div>
        <div className="card-block" style={{ marginBottom: 16, textAlign: "center" }}>
          <div style={{ fontSize: 12, color: palette.muted, marginBottom: 4 }}>TOTAL SAVED</div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 30, color: palette.accent }}>Ksh 54,000</div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {goals.map(g => {
            const pct = Math.round((g.saved / g.target) * 100);
            return (
              <div key={g.name} className="card-block">
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                  <div className="section-title" style={{ fontSize: 14 }}>{g.name}</div>
                  <span style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 12, color: palette.accent }}>{pct}%</span>
                </div>
                <div className="progress-bar" style={{ marginBottom: 8 }}>
                  <div className="progress-fill" style={{ width: `${pct}%` }}></div>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: palette.muted }}>
                  <span>Ksh {g.saved.toLocaleString()} saved</span>
                  <span>Goal: Ksh {g.target.toLocaleString()}</span>
                </div>
                <div className="divider" />
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <span style={{ fontSize: 12, color: palette.muted }}>Monthly: Ksh {g.monthly.toLocaleString()}</span>
                  <button className="pill pill-green" style={{ cursor: "pointer", fontSize: 11 }}>Contribute</button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <NavBar active="save" />
    </div>
  );
}

function Closeout() {
  return (
    <div style={{ padding: "20px 20px 0", height: "100%", overflow: "auto" }}>
      <div className="section-title" style={{ fontSize: 20, marginBottom: 4 }}>Monthly Closeout</div>
      <div style={{ color: palette.muted, fontSize: 13, marginBottom: 20 }}>February 2025 summary</div>
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {["Summary", "Surplus", "Sweep", "New Month"].map((s, i) => (
          <div key={s} style={{ flex: 1, textAlign: "center", fontSize: 10, color: i === 0 ? palette.accent : palette.muted, borderBottom: `2px solid ${i === 0 ? palette.accent : "transparent"}`, paddingBottom: 6 }}>{s}</div>
        ))}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 16 }}>
        {[["Income", "Ksh 85,000", palette.accent], ["Expenses", "Ksh 67,200", palette.danger], ["Saved", "Ksh 12,800", palette.accent], ["Surplus", "Ksh 5,000", palette.warning]].map(([l, v, c]) => (
          <div key={l} className="card-block" style={{ textAlign: "center" }}>
            <div style={{ fontSize: 11, color: palette.muted, marginBottom: 4 }}>{l}</div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 16, color: c }}>{v}</div>
          </div>
        ))}
      </div>
      <div className="card-block" style={{ marginBottom: 16 }}>
        <div style={{ fontSize: 13, marginBottom: 10 }}>Category Breakdown</div>
        {[["🍔 Food", "over", "-Ksh 3,600"], ["🏠 Rent", "ok", "Ksh 0"], ["🚗 Transport", "saved", "+Ksh 2,800"]].map(([cat, st, diff]) => (
          <div key={cat} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: `1px solid ${palette.border}` }}>
            <span style={{ fontSize: 13 }}>{cat}</span>
            <span style={{ fontSize: 13, color: st === "over" ? palette.danger : palette.accent }}>{diff}</span>
          </div>
        ))}
      </div>
      <button className="btn-primary">Sweep Surplus to Savings →</button>
    </div>
  );
}

function Settings() {
  const toggles = [
    ["Auto-logging (Notifications)", true], ["Email Parsing", true],
    ["Blockchain Sync (Base)", true], ["AI Categorization", true],
    ["Strict Budget Mode", false], ["AI Insights Feed", true],
  ];
  return (
    <div style={{ padding: "20px 20px 0", height: "100%", overflow: "auto", paddingBottom: 80 }}>
      <div className="section-title" style={{ fontSize: 20, marginBottom: 20 }}>Settings</div>
      <div className="card-block" style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 12 }}>
        <div style={{ width: 48, height: 48, borderRadius: "50%", background: `linear-gradient(135deg, ${palette.accent}, ${palette.purple})`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, color: "#000", fontFamily: "Syne", fontWeight: 800 }}>J</div>
        <div>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 15 }}>John Kamau</div>
          <div style={{ fontSize: 12, color: palette.muted }}>john@example.com</div>
          <div className="chain-badge" style={{ marginTop: 4, padding: "4px 8px" }}><span style={{ width: 6, height: 6, borderRadius: "50%", background: palette.accent, display: "inline-block" }}></span><span style={{ fontSize: 10 }}>0x3F…9a2c · Base</span></div>
        </div>
      </div>
      <div style={{ fontSize: 11, color: palette.muted, marginBottom: 10, fontFamily: "Syne", fontWeight: 600, letterSpacing: "0.05em", textTransform: "uppercase" }}>Auto-Logging Preferences</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 20 }}>
        {toggles.map(([label, on]) => (
          <div key={label} className="card-block" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 13 }}>{label}</span>
            <div style={{ width: 40, height: 22, borderRadius: 99, background: on ? palette.accent : palette.border, position: "relative", cursor: "pointer" }}>
              <div style={{ position: "absolute", top: 3, left: on ? 20 : 3, width: 16, height: 16, borderRadius: "50%", background: on ? "#000" : palette.muted, transition: "left 0.2s" }}></div>
            </div>
          </div>
        ))}
      </div>
      <button className="btn-ghost">Log out</button>
    </div>
  );
}

function MiniApp() {
  return (
    <div style={{ padding: "20px", height: "100%", overflow: "auto" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 18 }}>CoinTrack</div>
        <span className="pill pill-green" style={{ fontSize: 10 }}>🔵 Base Miniapp</span>
      </div>
      <div className="chain-badge" style={{ marginBottom: 16 }}>
        <span>⛓️</span>
        <span style={{ color: palette.muted, fontSize: 12 }}>Tracking onchain transactions from your wallet</span>
      </div>
      <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: palette.muted, marginBottom: 10, textTransform: "uppercase", letterSpacing: "0.05em" }}>Recent On-chain Activity</div>
      {[
        { desc: "Sent via MiniSend – Alice", amt: "-Ksh 2,000", cat: "🤝 Transfer", onchain: true },
        { desc: "Received – Bob MiniSend", amt: "+Ksh 5,000", cat: "💸 Income", onchain: true },
        { desc: "Manual: Groceries", amt: "-Ksh 1,200", cat: "🛒 Food", onchain: false },
      ].map(t => (
        <div key={t.desc} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 0", borderBottom: `1px solid ${palette.border}` }}>
          <div>
            <div style={{ fontSize: 13 }}>{t.desc}</div>
            <div style={{ fontSize: 11, color: palette.muted, display: "flex", gap: 6, alignItems: "center" }}>
              {t.cat}
              {t.onchain && <span className="pill pill-green" style={{ fontSize: 9 }}>Onchain</span>}
            </div>
          </div>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: t.amt.startsWith("+") ? palette.accent : palette.danger }}>{t.amt}</div>
        </div>
      ))}
      <button className="btn-primary" style={{ marginTop: 16 }}>+ Log Manual Expense</button>
      <button className="btn-ghost" style={{ marginTop: 10 }}>View Full Budget →</button>
    </div>
  );
}

function NavBar({ active }) {
  const items = [
    { id: "home", icon: "🏠", label: "Home" },
    { id: "budget", icon: "📊", label: "Budget" },
    { id: "tx", icon: "💸", label: "Transactions" },
    { id: "shop", icon: "🛒", label: "Shopping" },
    { id: "save", icon: "🎯", label: "Savings" },
  ];
  return (
    <div className="nav-bar">
      {items.map(i => (
        <div key={i.id} className={`nav-item ${active === i.id ? "active" : ""}`}>
          <span style={{ fontSize: 18 }}>{i.icon}</span>
          <span>{i.label}</span>
        </div>
      ))}
    </div>
  );
}

const screenComponents = {
  splash: Splash, onboarding1: Onboarding1, onboarding2: Onboarding2,
  register: Register, login: Login, setup1: Setup1, setup2: Setup2, setup3: Setup3,
  dashboard: Dashboard, budget: BudgetPage, category: CategoryDetail,
  transactions: Transactions, addtx: AddTransaction,
  shopping: ShoppingLists, shoppingdetail: ShoppingDetail,
  savings: Savings, closeout: Closeout, settings: Settings, miniapp: MiniApp,
};

// ─── MAIN APP ─────────────────────────────────────────────────────────────────

export default function App() {
  const [active, setActive] = useState("splash");

  const ScreenComponent = screenComponents[active] || Splash;

  const sectionFor = (id) => screens.onboarding.find(s => s.id === id) ? "onboarding" : "main";
  const currentSection = sectionFor(active);

  return (
    <>
      <style>{css}</style>
      <div style={{ minHeight: "100vh", background: palette.bg, display: "flex" }}>
        {/* Sidebar */}
        <div style={{ width: 220, minHeight: "100vh", background: palette.surface, borderRight: `1px solid ${palette.border}`, padding: "24px 0", flexShrink: 0, display: "flex", flexDirection: "column", overflow: "auto" }}>
          <div style={{ padding: "0 16px 20px" }}>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 18, color: palette.accent }}>CoinTrack</div>
            <div style={{ fontSize: 11, color: palette.muted, marginTop: 2 }}>MVP Screen Explorer</div>
          </div>
          <div style={{ padding: "0 12px", marginBottom: 8 }}>
            <div style={{ fontSize: 10, color: palette.muted, fontFamily: "Syne", fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 6, padding: "0 4px" }}>Onboarding</div>
            {screens.onboarding.map(s => (
              <div key={s.id} onClick={() => setActive(s.id)} style={{ padding: "8px 10px", borderRadius: 10, cursor: "pointer", fontSize: 12, marginBottom: 2, background: active === s.id ? `rgba(0,229,160,0.1)` : "transparent", color: active === s.id ? palette.accent : palette.muted, border: active === s.id ? `1px solid rgba(0,229,160,0.2)` : "1px solid transparent", transition: "all 0.15s" }}>
                {s.label}
              </div>
            ))}
          </div>
          <div style={{ padding: "0 12px" }}>
            <div style={{ fontSize: 10, color: palette.muted, fontFamily: "Syne", fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 6, padding: "0 4px" }}>Main App</div>
            {screens.main.map(s => (
              <div key={s.id} onClick={() => setActive(s.id)} style={{ padding: "8px 10px", borderRadius: 10, cursor: "pointer", fontSize: 12, marginBottom: 2, background: active === s.id ? `rgba(0,229,160,0.1)` : "transparent", color: active === s.id ? palette.accent : palette.muted, border: active === s.id ? `1px solid rgba(0,229,160,0.2)` : "1px solid transparent", transition: "all 0.15s" }}>
                {s.label}
              </div>
            ))}
          </div>
        </div>

        {/* Main content */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px 60px", gap: 24 }}>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 22, color: palette.text }}>{allScreens.find(s => s.id === active)?.label}</div>
            <div style={{ fontSize: 12, color: palette.muted, marginTop: 4 }}>
              {active === "miniapp" ? "Base Miniapp — limited to manual + onchain logging only" : active.startsWith("setup") || active === "onboarding1" || active === "onboarding2" ? "Flutter App — Onboarding" : active === "splash" || active === "register" || active === "login" ? "Flutter App — Auth" : "Flutter App — Main"}
            </div>
          </div>

          <div className="screen-phone">
            <div className="status-bar">
              <span>9:41</span>
              <span>●●●</span>
              <span>100%</span>
            </div>
            <div style={{ height: "calc(100% - 44px)", overflow: "hidden", position: "relative" }}>
              <ScreenComponent />
            </div>
          </div>

          {/* Navigation arrows */}
          <div style={{ display: "flex", gap: 12 }}>
            {[["← Prev", -1], ["Next →", 1]].map(([label, dir]) => {
              const idx = allScreens.findIndex(s => s.id === active);
              const target = allScreens[idx + dir];
              return (
                <button key={label} onClick={() => target && setActive(target.id)} disabled={!target} style={{ background: target ? palette.card : "transparent", border: `1px solid ${palette.border}`, borderRadius: 10, padding: "8px 16px", color: target ? palette.text : palette.border, fontSize: 13, cursor: target ? "pointer" : "default", fontFamily: "Syne", fontWeight: 600 }}>{label}</button>
              );
            })}
          </div>
        </div>

        {/* Right panel: notes */}
        <div style={{ width: 240, minHeight: "100vh", background: palette.surface, borderLeft: `1px solid ${palette.border}`, padding: "24px 16px", overflow: "auto" }}>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, color: palette.accent, marginBottom: 16 }}>Screen Notes</div>
          {active === "splash" && <Note title="Splash" items={["First impression screen", "CTA: Get Started / Log In", "Base onchain badge shown"]} />}
          {active === "onboarding1" && <Note title="Auto-Logging Intro" items={["Shows M-Pesa, email, blockchain sources", "Builds trust in automation", "No permissions asked yet"]} />}
          {active === "onboarding2" && <Note title="Base Sync" items={["Explains onchain storage", "Live transaction preview", "Positions Base as trust layer"]} />}
          {active === "register" && <Note title="Register" items={["Email + password", "OR Base wallet auth", "Wallet creates smart account silently"]} />}
          {active === "login" && <Note title="Login" items={["Email or wallet login", "JWT issued on auth", "Redirect to dashboard"]} />}
          {active === "setup1" && <Note title="Income Setup" items={["Wizard step 1 of 3", "Multiple income sources", "Stored in budgets collection"]} />}
          {active === "setup2" && <Note title="Budget Allocation" items={["50/30/20 presets", "Manual override", "Creates categories collection docs"]} />}
          {active === "setup3" && <Note title="Savings Goal" items={["Preset or custom goal", "Stored in goals collection", "Monthly contribution suggested by AI"]} />}
          {active === "dashboard" && <Note title="Dashboard" items={["Free-to-spend hero metric", "AI insight card", "Recent tx (auto + onchain badges)", "Quick actions"]} />}
          {active === "budget" && <Note title="Budget Overview" items={["Planned vs Actual per category", "Over-budget highlighted red", "Needs / Wants / Savings tags", "Add category CTA"]} />}
          {active === "category" && <Note title="Category Detail" items={["Overspend alert card", "All linked transactions listed", "Drill-down from budget page"]} />}
          {active === "transactions" && <Note title="Transactions" items={["Filter: All / Auto / Onchain / Manual", "Source badges", "Link to add transaction"]} />}
          {active === "addtx" && <Note title="Add Transaction" items={["AI category suggestion (HuggingFace)", "94% confidence shown", "Option to store on Base", "POST /transaction"]} />}
          {active === "shopping" && <Note title="Shopping Lists" items={["Color-coded budget status", "Green / Yellow / Red thresholds", "Links to budget category"]} />}
          {active === "shoppingdetail" && <Note title="Shopping List Detail" items={["Items with qty + price", "Remaining budget shown", "Checkout → creates transactions"]} />}
          {active === "savings" && <Note title="Savings Goals" items={["Progress bars per goal", "Monthly contribution amount", "Sweep surplus button on closeout"]} />}
          {active === "closeout" && <Note title="Month Closeout" items={["4-step wizard", "Category breakdown", "Surplus sweep to savings", "Generates monthly_reports doc"]} />}
          {active === "settings" && <Note title="Settings" items={["Wallet address shown", "Toggle auto-logging sources", "Toggle AI features", "POST /notifications/register"]} />}
          {active === "miniapp" && <Note title="Base Miniapp" items={["No notification access", "Onchain transactions auto-detected", "Manual expense logging only", "Shows last N on-chain txs", "Lightweight — no file install"]} />}
        </div>
      </div>
    </>
  );
}

function Note({ title, items }) {
  return (
    <div>
      <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 12, color: palette.text, marginBottom: 8 }}>{title}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
        {items.map(i => (
          <div key={i} style={{ fontSize: 12, color: palette.muted, display: "flex", gap: 6 }}>
            <span style={{ color: palette.accent, flexShrink: 0 }}>→</span>
            <span>{i}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
