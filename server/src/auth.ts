import jwt from 'jsonwebtoken';
import type { Request, Response, NextFunction } from 'express';

const SECRET = process.env.JWT_SECRET || 'korshi-dev-secret-change-me';

export type Role = 'super' | 'admin' | 'resident';
export interface TokenPayload {
  sub: string;
  role: Role;
  /** Neighborhood the principal belongs to. Absent for the super admin. */
  nid?: string;
}

export interface AuthedRequest extends Request {
  auth?: TokenPayload;
}

export function signToken(payload: TokenPayload): string {
  return jwt.sign(payload, SECRET, { expiresIn: '60d' });
}

function readToken(req: Request): TokenPayload | null {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(h.slice(7), SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

/** Neighborhood admin (scoped to one neighborhood via `req.auth.nid`). */
export function requireAdmin(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || p.role !== 'admin' || !p.nid) return res.status(401).json({ error: 'unauthorized' });
  req.auth = p;
  next();
}

/** Top-level admin who manages neighborhoods. */
export function requireSuper(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || p.role !== 'super') return res.status(401).json({ error: 'unauthorized' });
  req.auth = p;
  next();
}

export function requireResident(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || p.role !== 'resident' || !p.nid) return res.status(401).json({ error: 'unauthorized' });
  req.auth = p;
  next();
}

/** Resident OR neighborhood admin (used for device-token registration). */
export function requireUser(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || (p.role !== 'resident' && p.role !== 'admin') || !p.nid) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  req.auth = p;
  next();
}
