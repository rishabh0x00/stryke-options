"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useState } from "react";
import { format } from "date-fns";
import { CalendarIcon } from "lucide-react";
import { Button } from "../../components/ui/button";
import { Input } from "../../components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "../../components/ui/form";
import { Popover, PopoverContent, PopoverTrigger } from "../../components/ui/popover";
import { Calendar } from "../../components/ui/calendar";
import { Select, SelectTrigger, SelectContent, SelectItem, SelectValue } from "../../components/ui/select";

const formSchema = z.object({
  assetType: z.enum(["ETH", "BTC", "USDT"], { required_error: "Asset Type is required" }),
  optionType: z.enum(["call", "put"], { required_error: "Option Type is required" }),
  actionType: z.enum(["buy", "sell"], { required_error: "Action Type is required" }),
  strikePrice: z.coerce.number().positive("Strike Price must be positive"),
  premium: z.coerce.number().positive("Premium must be positive"),
  expiryDate: z.date().min(new Date(), "Expiry Date must be in the future"),
});

type OptionFormData = z.infer<typeof formSchema>;

export default function OptionCreationForm() {
  const [, setSelectedDate] = useState<Date | undefined>(undefined);

  const form = useForm<OptionFormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      assetType: "ETH",
      optionType: "call",
      actionType: "buy",
      strikePrice: undefined,
      premium: undefined,
      expiryDate: undefined,
    },
  });

  const onSubmit = async (values: OptionFormData) => {
    console.log("Form Data:", values);
  };

  return (
    <div className="flex flex-col gap-6 min-h-screen w-full items-center justify-center p-6 md:p-10">
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 w-full max-w-md">
          <FormField
            control={form.control}
            name="assetType"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Asset</FormLabel>
                <Select onValueChange={field.onChange} value={field.value}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select Asset" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ETH">Ethereum (ETH)</SelectItem>
                    <SelectItem value="BTC">Bitcoin (BTC)</SelectItem>
                    <SelectItem value="USDT">Tether (USDT)</SelectItem>
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="optionType"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Option Type</FormLabel>
                <Select onValueChange={field.onChange} value={field.value}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select Option Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="call">Call (Bullish)</SelectItem>
                    <SelectItem value="put">Put (Bearish)</SelectItem>
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="actionType"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Action Type</FormLabel>
                <Select onValueChange={field.onChange} value={field.value}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select Action Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="buy">Buy</SelectItem>
                    <SelectItem value="sell">Sell</SelectItem>
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="strikePrice"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Strike Price (ETH)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    placeholder="Enter strike price"
                    {...field}
                    onChange={(e) => field.onChange(Number(e.target.value))}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="premium"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Premium (ETH)</FormLabel>
                <FormControl>
                  <Input
                    type="number"
                    placeholder="Enter premium"
                    {...field}
                    onChange={(e) => field.onChange(Number(e.target.value))}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="expiryDate"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Expiry Date</FormLabel>
                <Popover>
                  <PopoverTrigger asChild>
                    <FormControl>
                      <Button variant="outline" className="w-full pl-3 text-left">
                        {field.value ? format(field.value, "PPP") : "Pick a date"}
                        <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                      </Button>
                    </FormControl>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0">
                    <Calendar
                      mode="single"
                      selected={field.value}
                      onSelect={(date) => {
                        setSelectedDate(date);
                        field.onChange(date);
                      }}
                      disabled={(date) => date < new Date()}
                      initialFocus
                    />
                  </PopoverContent>
                </Popover>
                <FormMessage />
              </FormItem>
            )}
          />

          <Button type="submit" className="w-full">
            Create Option
          </Button>
        </form>
      </Form>
    </div>
  );
}
