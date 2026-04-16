const crypto = require('crypto');

let nodemailer = null;
try {
  // Optional dependency: available when SMTP sending is configured.
  nodemailer = require('nodemailer');
} catch (_) {
  nodemailer = null;
}

class MailService {
  _normalizeFrontendOrigin(frontendOrigin) {
    const candidate = String(frontendOrigin || '').trim();
    if (!candidate) {
      return null;
    }
    if (!/^https?:\/\//i.test(candidate)) {
      return null;
    }
    return candidate.replace(/\/$/, '');
  }

  _buildResetUrl(resetToken, frontendOrigin = null) {
    const normalizedOrigin = this._normalizeFrontendOrigin(frontendOrigin);
    const frontendUrl = (normalizedOrigin || process.env.FRONTEND_URL || 'http://localhost:57477').replace(/\/$/, '');
    return `${frontendUrl}/#/reset-password?token=${encodeURIComponent(resetToken)}`;
  }

  async sendPasswordResetEmail({ email, username, resetToken, expiresAt, frontendOrigin }) {
    const resetUrl = this._buildResetUrl(resetToken, frontendOrigin);
    const expiresLabel = expiresAt.toISOString();
    const subject = 'Réinitialisation de votre mot de passe Sunspace';
    const text = [
      `Bonjour ${username || ''}`.trim(),
      '',
      'Vous avez demandé à réinitialiser votre mot de passe.',
      `Lien de réinitialisation: ${resetUrl}`,
      `Ce lien expire le: ${expiresLabel}`,
      '',
      'Si vous n\'êtes pas à l\'origine de cette demande, ignorez ce message.',
    ].join('\n');

    const html = `
      <div style="font-family:Arial,sans-serif;line-height:1.6;color:#0f172a">
        <h2 style="color:#1d6ff2;margin-bottom:8px">Réinitialisation de mot de passe</h2>
        <p>Bonjour ${username || ''},</p>
        <p>Vous avez demandé à réinitialiser votre mot de passe sur Sunspace.</p>
        <p>
          <a href="${resetUrl}" style="display:inline-block;padding:12px 18px;background:#1d6ff2;color:#fff;text-decoration:none;border-radius:8px;font-weight:700;">Réinitialiser mon mot de passe</a>
        </p>
        <p>Ce lien expire le <strong>${expiresLabel}</strong>.</p>
        <p style="color:#64748b">Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.</p>
      </div>
    `;

    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = Number(process.env.SMTP_PORT || '587');
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const fromAddress = process.env.SMTP_FROM || smtpUser || 'no-reply@sunspace.local';

    if (nodemailer && smtpHost && smtpUser && smtpPass) {
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: String(process.env.SMTP_SECURE || 'false').toLowerCase() === 'true',
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      try {
        await transporter.sendMail({
          from: fromAddress,
          to: email,
          subject,
          text,
          html,
        });

        return { delivered: true, resetUrl };
      } catch (error) {
        console.warn('[mail] Echec envoi SMTP, bascule en mode simulation:', error.message);
      }
    }

    const missing = [];
    if (!smtpHost) missing.push('SMTP_HOST');
    if (!smtpUser) missing.push('SMTP_USER');
    if (!smtpPass) missing.push('SMTP_PASS');

    console.warn('[mail] SMTP non configuré, envoi réel désactivé. Variables manquantes:', missing.join(', ') || 'aucune');
    console.log('\n' + '='.repeat(80));
    console.log('[mail] 📧 EMAIL DE RÉINITIALISATION GÉNÉRÉ (MODE TEST)');
    console.log('='.repeat(80));
    console.log(`À: ${email}`);
    console.log(`Sujet: ${subject}`);
    console.log(`Expire le: ${expiresLabel}`);
    console.log('');
    console.log('LIEN DE RÉINITIALISATION (clickable):');
    console.log(`→ ${resetUrl}`);
    console.log('');
    console.log('Contenu du message:');
    console.log(text);
    console.log('='.repeat(80) + '\n');
    return { delivered: false, resetUrl };
  }
}

module.exports = new MailService();
