'use client';

import * as React from 'react';
import { ChevronsUpDown, LogOut } from 'lucide-react';
import { Button } from '../../components/ui/button';
import {
  Command,
  CommandGroup,
  CommandItem,
  CommandList,
} from '../../components/ui/command';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '../../components/ui/popover';
import { useWallet } from '../../context/WalletContext';

export function WalletCombobox() {
  const [open, setOpen] = React.useState(false);
  const { isConnected, account, connectWallet, disconnectWallet } = useWallet();

  return (
    <div>
      {isConnected ? (
        <Popover open={open} onOpenChange={setOpen}>
          <PopoverTrigger asChild>
            <Button
              variant="outline"
              role="combobox"
              aria-expanded={open}
              className="w-[200px] justify-between"
            >
              {account
                ? `${account.slice(0, 6)}...${account.slice(-4)}`
                : 'Account'}
              <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-[200px] p-0">
            <Command>
              <CommandList>
                <CommandGroup>
                  <CommandItem
                    onSelect={() => {
                      disconnectWallet();
                      setOpen(false);
                    }}
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    <span>Disconnect</span>
                  </CommandItem>
                </CommandGroup>
              </CommandList>
            </Command>
          </PopoverContent>
        </Popover>
      ) : (
        <Button variant="default" onClick={connectWallet} style={{borderRadius: '80px',backgroundColor:"#311c11",color:"#fc72ff", fontWeight:"535", fontSize:"14px"}}>
          Connect
        </Button>
      )}
    </div>
  );
}
