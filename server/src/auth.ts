import jwt from 'jsonwebtoken';
import type { Request, Response, NextFunction } from 'express';

const SECRET = process.env.JWT_SECRET || 'korshi-dev-secret-change-me';

export type Role = 'admin' | 'resident';
export interface TokenPayload {
  sub: string;
  role: Role;
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

export function requireAdmin(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || p.role !== 'admin') return res.status(401).json({ error: 'unauthorized' });
  req.auth = p;
  next();
}

export function requireResident(req: AuthedRequest, res: Response, next: NextFunction) {
  const p = readToken(req);
  if (!p || p.role !== 'resident') return res.status(401).json({ error: 'unauthorized' });
  req.auth = p;
  next();
}
