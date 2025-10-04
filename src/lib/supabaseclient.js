// src/lib/supabaseClient.js
import { createClient } from '@supabase/supabase-js'

const url = process.env.VITE_SUPABASE_URL
const anonKey = process.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(url, anonKey)