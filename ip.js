import { isIP } from 'node:net';
export function normalizeIPs(text) {
  const entries = text.split(/[\s,;]+/).filter(Boolean);
  for (const entry of entries) {
    const [ip, prefix, ...extra] = entry.split('/');
    const version = isIP(ip);
    if (!version || extra.length || (prefix !== undefined && (!/^\d+$/.test(prefix) || Number(prefix) > (version === 4 ? 32 : 128)))) throw new Error(`IP ou rede inválida: ${entry}`);
  }
  return [...new Set(entries)].join('\n');
}
