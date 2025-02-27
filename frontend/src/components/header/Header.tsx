"use client";

import Link from "next/link";
import { useState } from "react";
import {
    NavigationMenu,
    NavigationMenuList,
    NavigationMenuItem,
    NavigationMenuLink,
} from "@/components/ui/navigation-menu";
import { Menu, X } from "lucide-react";
import { useWallet } from "@/context/WalletContext";
import { WalletCombobox } from "./WalletCombobox";

export function Header() {
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const { isConnected } = useWallet();

    console.log("isConnected", isConnected);

    return (
        <header className="sticky top-0 z-50 w-full border-b bg-[#131313] backdrop-blur">
            <div className="mx-8 flex h-16 items-center justify-between">
                <nav className="hidden md:flex">
                    <NavigationMenu>
                        <NavigationMenuList className="flex space-x-6">
                            <NavigationMenuItem>
                                <NavigationMenuLink asChild>
                                    <Link href="/dashboard" className="text-[#9b9b9b] text-[18px] font-[485] hover:text-white">
                                        Dashboard
                                    </Link>
                                </NavigationMenuLink>
                            </NavigationMenuItem>
                            <NavigationMenuItem>
                                <NavigationMenuLink asChild>
                                    <Link href="/create-option" className="text-[#9b9b9b] text-[18px] font-[485] hover:text-white">
                                        Create Option
                                    </Link>
                                </NavigationMenuLink>
                            </NavigationMenuItem>
                        </NavigationMenuList>
                    </NavigationMenu>
                </nav>

                <div className="flex items-center">
                    <WalletCombobox />
                    <button
                        className="md:hidden"
                        onClick={() => setIsMenuOpen(!isMenuOpen)}
                        aria-label="Toggle Menu"
                    >
                        {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
                    </button>
                </div>
            </div>


            {isMenuOpen && (
                <nav className="md:hidden bg-background">
                    <Link href="/dashboard" className="block px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground">
                        Dashboard
                    </Link>
                    <Link href="/create-option" className="block px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground">
                        Create Option
                    </Link>
                    <Link href="/profile" className="block px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground">
                        Profile
                    </Link>
                </nav>
            )}
        </header>
    );
}
