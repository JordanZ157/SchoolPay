# Drizzle Studio - School Payment Database

This is a utility project for managing the School Payment System SQLite database using Drizzle Studio.

## Prerequisites

- Node.js 18+ installed
- npm or yarn

## Setup

1. Install dependencies:
```bash
npm install
```

2. Open Drizzle Studio:
```bash
npm run studio
```

This will open Drizzle Studio in your browser at `https://local.drizzle.studio`

## Available Scripts

- `npm run studio` - Open Drizzle Studio to browse and manage the database
- `npm run push` - Push schema changes to the database
- `npm run generate` - Generate migrations
- `npm run migrate` - Run migrations

## Important Notes

- This project uses the same SQLite database as the Laravel backend (`../database/database.sqlite`)
- Changes made in Drizzle Studio will affect the Laravel application
- The schema in `src/schema.ts` matches the Laravel migrations exactly
- **Do not use `npm run push` to sync schema** - Schema changes should always be done through Laravel migrations to maintain consistency

## Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@school.com | password |
| Bendahara | bendahara@school.com | password |
| Wali Kelas | walikelas@school.com | password |
| Siswa 1 | siswa1@school.com | password |
| Siswa 2 | siswa2@school.com | password |
| Orang Tua 1 | orangtua1@school.com | password |
| Orang Tua 2 | orangtua2@school.com | password |
