import "./globals.css";
import { Providers } from "@/components/providers";
import { Header } from "@/components/header";
export const metadata = { title: "ProofPay", description: "Outcome-based USDC bounties on Arc." };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="en" suppressHydrationWarning><body suppressHydrationWarning><Providers><Header/><main className="mx-auto min-h-screen max-w-6xl px-4 py-8 md:px-6">{children}</main></Providers></body></html>; }
