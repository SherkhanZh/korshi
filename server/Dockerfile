# ─── Build stage ───
# Node 22 is required for the built-in `node:sqlite` module.
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ─── Runtime stage ───
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
EXPOSE 3000
# --experimental-sqlite enables the built-in SQLite engine.
CMD ["node", "--experimental-sqlite", "dist/index.js"]
