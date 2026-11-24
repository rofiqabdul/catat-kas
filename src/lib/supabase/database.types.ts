
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "public": {
          Tables: {
            "budgets": {
                  Row: {
                    "amount_limit": number,"category_id": string,"id": string,"month_year": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount_limit": number,"category_id": string,"id"?: string,"month_year": string,"user_id"?: string
                  }
                  Update: {
                    "amount_limit"?: number,"category_id"?: string,"id"?: string,"month_year"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "budgets_category_id_fkey"
      columns: ["category_id"]
isOneToOne: false
      referencedRelation: "categories"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "budgets_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"categories": {
                  Row: {
                    "icon": string | null,"id": string,"is_archived": boolean,"is_system": boolean,"name": string,"scope": string,"type": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "icon"?: string | null,"id"?: string,"is_archived"?: boolean,"is_system"?: boolean,"name": string,"scope": string,"type": string,"user_id"?: string
                  }
                  Update: {
                    "icon"?: string | null,"id"?: string,"is_archived"?: boolean,"is_system"?: boolean,"name"?: string,"scope"?: string,"type"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "categories_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"debts": {
                  Row: {
                    "affect_wallet": boolean,"created_at": string | null,"due_date": string | null,"id": string,"note": string | null,"person_name": string,"remaining_amount": number,"status": string,"total_amount": number,"type": string,"user_id": string,"wallet_id": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "affect_wallet"?: boolean,"created_at"?: string | null,"due_date"?: string | null,"id"?: string,"note"?: string | null,"person_name": string,"remaining_amount": number,"status"?: string,"total_amount": number,"type": string,"user_id"?: string,"wallet_id"?: string | null
                  }
                  Update: {
                    "affect_wallet"?: boolean,"created_at"?: string | null,"due_date"?: string | null,"id"?: string,"note"?: string | null,"person_name"?: string,"remaining_amount"?: number,"status"?: string,"total_amount"?: number,"type"?: string,"user_id"?: string,"wallet_id"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "debts_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "debts_wallet_id_fkey"
      columns: ["wallet_id"]
isOneToOne: false
      referencedRelation: "wallets"
      referencedColumns: ["id"]
    }
                  ]
                },"profiles": {
                  Row: {
                    "created_at": string | null,"email": string,"full_name": string | null,"id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string | null,"email": string,"full_name"?: string | null,"id": string
                  }
                  Update: {
                    "created_at"?: string | null,"email"?: string,"full_name"?: string | null,"id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"transactions": {
                  Row: {
                    "amount": number,"category_id": string | null,"created_at": string | null,"debt_id": string | null,"destination_wallet_id": string | null,"id": string,"is_cross_scope": boolean,"note": string | null,"receipt_path": string | null,"transaction_date": string,"type": string,"user_id": string,"wallet_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount": number,"category_id"?: string | null,"created_at"?: string | null,"debt_id"?: string | null,"destination_wallet_id"?: string | null,"id"?: string,"is_cross_scope"?: boolean,"note"?: string | null,"receipt_path"?: string | null,"transaction_date": string,"type": string,"user_id"?: string,"wallet_id": string
                  }
                  Update: {
                    "amount"?: number,"category_id"?: string | null,"created_at"?: string | null,"debt_id"?: string | null,"destination_wallet_id"?: string | null,"id"?: string,"is_cross_scope"?: boolean,"note"?: string | null,"receipt_path"?: string | null,"transaction_date"?: string,"type"?: string,"user_id"?: string,"wallet_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "transactions_category_id_fkey"
      columns: ["category_id"]
isOneToOne: false
      referencedRelation: "categories"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "transactions_debt_id_fkey"
      columns: ["debt_id"]
isOneToOne: false
      referencedRelation: "debts"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "transactions_destination_wallet_id_fkey"
      columns: ["destination_wallet_id"]
isOneToOne: false
      referencedRelation: "wallets"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "transactions_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "transactions_wallet_id_fkey"
      columns: ["wallet_id"]
isOneToOne: false
      referencedRelation: "wallets"
      referencedColumns: ["id"]
    }
                  ]
                },"wallets": {
                  Row: {
                    "balance": number,"created_at": string | null,"id": string,"is_archived": boolean,"name": string,"scope": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "balance"?: number,"created_at"?: string | null,"id"?: string,"is_archived"?: boolean,"name": string,"scope": string,"user_id"?: string
                  }
                  Update: {
                    "balance"?: number,"created_at"?: string | null,"id"?: string,"is_archived"?: boolean,"name"?: string,"scope"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "wallets_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "create_debt":
{ Args: { "p_affect_wallet"?: boolean,"p_due_date"?: string,"p_note"?: string,"p_person_name": string,"p_total_amount": number,"p_type": string,"p_wallet_id"?: string }; Returns: string
                           },
"create_transaction":
{ Args: { "p_amount": number,"p_category_id"?: string,"p_destination_wallet_id"?: string,"p_note"?: string,"p_receipt_path"?: string,"p_transaction_date": string,"p_type": string,"p_wallet_id": string }; Returns: string
                           },
"delete_transaction":
{ Args: { "p_transaction_id": string }; Returns: string
                           },
"get_monthly_report":
{ Args: { "p_month_year": string,"p_scope": string }; Returns: Json
                           },
"pay_debt":
{ Args: { "p_debt_id": string,"p_note"?: string,"p_payment_amount": number }; Returns: string
                           },
"reconcile_wallet":
{ Args: { "p_actual_balance": number,"p_wallet_id": string }; Returns: string
                           },
"update_transaction":
{ Args: { "p_amount": number,"p_category_id"?: string,"p_destination_wallet_id"?: string,"p_note"?: string,"p_receipt_path"?: string,"p_transaction_date": string,"p_transaction_id": string,"p_type": string,"p_wallet_id": string }; Returns: string
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "public": {
          Enums: {
            
          }
        }
} as const
