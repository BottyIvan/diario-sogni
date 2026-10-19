import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import styles from './index.module.css';

const guides = [
  {
    title: 'Installa l’app',
    description: 'I passaggi per scaricare Diario dei sogni su Android o installarlo su iPhone.',
    link: '/docs/installazione-android',
    label: 'Android e iPhone',
  },
  {
    title: 'Usa il diario su telefono e PC',
    description: 'Collega una cartella, sincronizza i sogni e ritrovali sui tuoi dispositivi.',
    link: '/docs/guida-archivio-condiviso',
    label: 'Guida pratica',
  },
  {
    title: 'Informazioni per iPhone',
    description: 'Come installare la versione iPhone via Safari e risolvere i problemi comuni.',
    link: '/docs/ios-revisione-e-test',
    label: 'Installazione OTA',
  },
];

function GuideCard({ title, description, link, label }) {
  return (
    <Link className={styles.card} to={link}>
      <span className={styles.cardLabel}>{label}</span>
      <h2>{title}</h2>
      <p>{description}</p>
      <span className={styles.cardLink}>Apri la guida <span aria-hidden="true">→</span></span>
    </Link>
  );
}

export default function Home() {
  const androidRelease = 'https://github.com/SboMusic/diario-sogni/releases/tag/v0.4.2';
  const iphoneInstall =
    'itms-services://?action=download-manifest&url=https://github.com/BottyIvan/diario-sogni/releases/latest/download/manifest.plist';

  return (
    <Layout
      title="Guide e assistenza"
      description="Guide per installare Diario dei sogni, usare l’app e sincronizzare i tuoi sogni."
    >
      <main>
        <header className={styles.hero}>
          <div className="container">
            <p className={styles.eyebrow}>Diario dei sogni · Guide</p>
            <h1>Serve una mano?</h1>
            <p className={styles.lead}>
              Trova qui le istruzioni per installare l’app e usare il tuo diario, passo dopo passo.
            </p>
            <div className={styles.actions}>
              <Link className={styles.primaryButton} to="/docs/installazione-android">
                Come installare l’app
              </Link>
              <Link className={styles.secondaryButton} to="/docs/guida-archivio-condiviso">
                Come usare il diario
              </Link>
            </div>
          </div>
        </header>

        <section className={`container ${styles.section}`}>
          <div className={styles.sectionHeading}>
            <p className={styles.eyebrow}>Guide più richieste</p>
            <h2>Da dove vuoi iniziare?</h2>
          </div>
          <div className={styles.grid}>
            {guides.map((guide) => <GuideCard key={guide.title} {...guide} />)}
          </div>
        </section>

        <section className={styles.installBanner}>
          <div className={`container ${styles.bannerInner}`}>
            <div>
              <p className={styles.eyebrow}>Pronto per iniziare?</p>
              <h2>Installa Diario dei sogni</h2>
              <p>Scegli il tuo telefono per aprire il download o avviare l’installazione.</p>
            </div>
            <div className={styles.actions}>
              <a className={styles.primaryButton} href={androidRelease}>
                Scarica per Android
              </a>
              <a className={styles.secondaryButton} href={iphoneInstall}>
                Installa su iPhone
              </a>
            </div>
          </div>
        </section>

        <section className={`container ${styles.more}`}>
          <h2>Tutte le guide</h2>
          <p>
            Per informazioni tecniche e di progetto, consulta la <Link to="/docs/analisi-funzionale-diario-sogni">documentazione completa</Link>.
          </p>
          <Link className={styles.textLink} to="/docs/installazione-android">
            Sfoglia le guide <span aria-hidden="true">→</span>
          </Link>
        </section>
      </main>
    </Layout>
  );
}
