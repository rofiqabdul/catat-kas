
export type UUID = string;
export type DateString = string;
export type TimestampString = string;
export type NumericAmount = number;

export type Scope = 'business' | 'personal' | 'both';
export type WalletScope = Exclude<Scope, 'both'>;
export type CategoryScope = Scope;

export type TransactionType = 'income' | 'expense' | 'transfer';

export type DebtType = 'receivable' | 'payable';
export type DebtStatus = 'unpaid' | 'partial' | 'paid';

export interface Profile {
	id: UUID;
	email: string;
	full_name: string | null;
	created_at: TimestampString | null;
}

export interface Wallet {
	id: UUID;
	user_id: UUID;
	name: string;
	scope: WalletScope;
	balance: NumericAmount;
	is_archived: boolean;
	created_at: TimestampString | null;
}

export interface Category {
	id: UUID;
	user_id: UUID;
	name: string;
	type: Exclude<TransactionType, 'transfer'>;
	scope: CategoryScope;
	icon: string | null;
	is_system: boolean;
	is_archived: boolean;
}

export interface Transaction {
	id: UUID;
	user_id: UUID;
	wallet_id: UUID;
	destination_wallet_id: UUID | null;
	category_id: UUID | null;
	debt_id: UUID | null;
	type: TransactionType;
	amount: NumericAmount;
	is_cross_scope: boolean;
	note: string | null;
	receipt_path: string | null;
	transaction_date: DateString;
	created_at: TimestampString | null;
}

export interface Debt {
	id: UUID;
	user_id: UUID;
	wallet_id: UUID | null;
	type: DebtType;
	person_name: string;
	total_amount: NumericAmount;
	remaining_amount: NumericAmount;
	affect_wallet: boolean;
	due_date: DateString | null;
	status: DebtStatus;
	note: string | null;
	created_at: TimestampString | null;
}

export interface Budget {
	id: UUID;
	user_id: UUID;
	category_id: UUID;
	amount_limit: NumericAmount;
	month_year: string;
}
