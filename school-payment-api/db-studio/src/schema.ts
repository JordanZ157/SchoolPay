/**
 * Drizzle ORM Schema for School Payment System
 * Matches Laravel migrations exactly for Drizzle Studio compatibility
 */

import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';

// ==================== USERS TABLE ====================
export const users = sqliteTable('users', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    name: text('name').notNull(),
    email: text('email').notNull().unique(),
    emailVerifiedAt: text('email_verified_at'),
    password: text('password').notNull(),
    role: text('role', { enum: ['admin', 'bendahara', 'wali_kelas', 'siswa', 'orang_tua'] }).default('siswa'),
    studentId: integer('student_id'),
    avatarUrl: text('avatar_url'),
    rememberToken: text('remember_token'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== STUDENTS TABLE ====================
export const students = sqliteTable('students', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    nis: text('nis').notNull().unique(),
    name: text('name').notNull(),
    className: text('class_name').notNull(),
    major: text('major'),
    parentId: integer('parent_id'),
    parentName: text('parent_name'),
    parentPhone: text('parent_phone'),
    parentEmail: text('parent_email'),
    status: text('status', { enum: ['active', 'inactive', 'graduated'] }).default('active'),
    avatarUrl: text('avatar_url'),
    enrolledAt: text('enrolled_at'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== FEE CATEGORIES TABLE ====================
export const feeCategories = sqliteTable('fee_categories', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    name: text('name').notNull(),
    description: text('description'),
    type: text('type', { enum: ['akademik', 'non_akademik', 'insidental', 'administratif'] }).default('akademik'),
    frequency: text('frequency', { enum: ['once', 'monthly', 'semester', 'yearly'] }).default('monthly'),
    baseAmount: real('base_amount').default(0),
    isActive: integer('is_active', { mode: 'boolean' }).default(true),
    allowInstallment: integer('allow_installment', { mode: 'boolean' }).default(false),
    maxInstallments: integer('max_installments'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== FEE RATES TABLE ====================
export const feeRates = sqliteTable('fee_rates', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    categoryId: integer('category_id').notNull().references(() => feeCategories.id, { onDelete: 'cascade' }),
    classLevel: text('class_level'),
    academicYear: text('academic_year').notNull(),
    amount: real('amount').notNull(),
    installmentRules: text('installment_rules'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== INVOICES TABLE ====================
export const invoices = sqliteTable('invoices', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    invoiceNumber: text('invoice_number').notNull().unique(),
    studentId: integer('student_id').notNull().references(() => students.id, { onDelete: 'cascade' }),
    categoryId: integer('category_id').notNull().references(() => feeCategories.id, { onDelete: 'cascade' }),
    period: text('period').notNull(),
    totalAmount: real('total_amount').notNull(),
    paidAmount: real('paid_amount').default(0),
    status: text('status', { enum: ['unpaid', 'paid', 'partial', 'expired', 'cancelled'] }).default('unpaid'),
    dueDate: text('due_date').notNull(),
    notes: text('notes'),
    createdBy: integer('created_by'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== INVOICE ITEMS TABLE ====================
export const invoiceItems = sqliteTable('invoice_items', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    invoiceId: integer('invoice_id').notNull().references(() => invoices.id, { onDelete: 'cascade' }),
    description: text('description').notNull(),
    amount: real('amount').notNull(),
    quantity: integer('quantity').default(1),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== TRANSACTIONS TABLE ====================
export const transactions = sqliteTable('transactions', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    orderId: text('order_id').notNull().unique(),
    invoiceId: integer('invoice_id').notNull().references(() => invoices.id, { onDelete: 'cascade' }),
    grossAmount: real('gross_amount').notNull(),
    paymentType: text('payment_type'),
    status: text('status', { enum: ['pending', 'settlement', 'capture', 'deny', 'cancel', 'expire', 'refund'] }).default('pending'),
    transactionTime: text('transaction_time'),
    settlementTime: text('settlement_time'),
    referenceNumber: text('reference_number'),
    rawPayload: text('raw_payload'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== RECEIPTS TABLE ====================
export const receipts = sqliteTable('receipts', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    invoiceId: integer('invoice_id').notNull().references(() => invoices.id, { onDelete: 'cascade' }),
    receiptNumber: text('receipt_number').notNull().unique(),
    issuedAt: text('issued_at'),
    pdfUrl: text('pdf_url'),
    metadata: text('metadata'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== AUDIT LOGS TABLE ====================
export const auditLogs = sqliteTable('audit_logs', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    userId: integer('user_id'),
    action: text('action').notNull(),
    entity: text('entity').notNull(),
    entityId: integer('entity_id'),
    before: text('before'),
    after: text('after'),
    ipAddress: text('ip_address'),
    userAgent: text('user_agent'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== CHATBOT SESSIONS TABLE ====================
export const chatbotSessions = sqliteTable('chatbot_sessions', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    lastIntent: text('last_intent'),
    contextJson: text('context_json'),
    lastActiveAt: text('last_active_at'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== CHATBOT LOGS TABLE ====================
export const chatbotLogs = sqliteTable('chatbot_logs', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    message: text('message').notNull(),
    intent: text('intent'),
    response: text('response').notNull(),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});

// ==================== LARAVEL INTERNAL TABLES ====================
// These are Laravel's internal tables, included for completeness

export const passwordResetTokens = sqliteTable('password_reset_tokens', {
    email: text('email').primaryKey(),
    token: text('token').notNull(),
    createdAt: text('created_at'),
});

export const failedJobs = sqliteTable('failed_jobs', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    uuid: text('uuid').notNull().unique(),
    connection: text('connection').notNull(),
    queue: text('queue').notNull(),
    payload: text('payload').notNull(),
    exception: text('exception').notNull(),
    failedAt: text('failed_at'),
});

export const personalAccessTokens = sqliteTable('personal_access_tokens', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    tokenableType: text('tokenable_type').notNull(),
    tokenableId: integer('tokenable_id').notNull(),
    name: text('name').notNull(),
    token: text('token').notNull().unique(),
    abilities: text('abilities'),
    lastUsedAt: text('last_used_at'),
    expiresAt: text('expires_at'),
    createdAt: text('created_at'),
    updatedAt: text('updated_at'),
});
