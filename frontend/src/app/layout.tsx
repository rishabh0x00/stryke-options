import "./globals.css";
import { WalletProvider } from "../context/WalletContext";

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="relative h-full w-full bg-white">
        <WalletProvider>
          <div className="glass-container w-full h-full">{children}</div>
        </WalletProvider>
      </body>
    </html>
  );
}
