"use client";

import { Shield, Lock, Activity } from 'lucide-react';
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { features, steps } from "../lib/constants";

export default function HomePage() {
  const router = useRouter();

  return (
    <div className="p-0">
      <section className="flex flex-col md:flex-row items-center justify-between text-white px-8 py-16">
        <div className="md:w-1/2 text-center md:text-left">
          <h1 className="text-4xl font-bold mb-4">
            Decentralized Options Vault: Lock Uniswap V3 LP & Mint Options
          </h1>
          <p className="text-lg text-gray-300 mb-6">
            Unlock the power of decentralized options with our innovative vault, leveraging Uniswap V3 LP positions as collateral.
          </p>
          <Button className="bg-purple-500" onClick={() => router.push("/dashboard")}>Launch App</Button>
        </div>
        <div className="md:w-1/2 flex justify-center mt-8 md:mt-0">
          <Image
            src="/home.jpg"
            alt="Decentralized Vault"
            width={400}
            height={400}
            className="rounded-lg shadow-lg"
          />
        </div>
      </section>
      <section className="bg-gradient-to-b from-black to-gray-900 text-white py-36 px-8">
        <div className="max-w-5xl mx-auto text-center">
          <h2 className="text-3xl md:text-4xl font-semibold mb-8">
            Introducing the Options Vault: How it Works
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {features.map((feature, index) => (
              <Card key={index} className="bg-gray-800 border-none text-center">
                <CardContent className="p-6">
                  <h3 className="text-xl font-semibold text-purple-300">
                    {feature.title}
                  </h3>
                  <p className="text-gray-400 mt-2">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>
      <section className="bg-purple-900 text-white py-36 px-6">
        <div className="max-w-5xl mx-auto text-center">
          <h2 className="text-3xl font-semibold mb-6 pb-14">
            React Frontend: User Interface & Interaction
          </h2>
          <div className="flex flex-col md:flex-row justify-center items-center gap-4">
            {steps.map((step, index) => (
              <div key={index} className="flex flex-col items-center text-center">
                <div className="relative bg-purple-800 text-xl font-bold py-3 px-6 rounded-md flex items-center justify-center min-w-[80px]">
                  {step.number}
                </div>
                <div className="mt-4">
                  <h3 className="text-lg font-semibold">{step.title}</h3>
                  <p className="text-sm mt-1">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
      <section className="relative w-full h-auto bg-cover bg-center text-white py-36 px-8" style={{ backgroundImage: 'url(/your-background-image.jpg)' }}>
        <div className="absolute inset-0 bg-black bg-opacity-60"></div>
        <div className="relative max-w-6xl mx-auto text-center">
          <h2 className="text-3xl md:text-5xl font-bold mb-8 pb-10">Security Considerations: Audits & Best Practices</h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="flex flex-col items-center text-center">
              <Lock size={48} className="text-pink-400" />
              <h3 className="text-xl font-semibold mt-4">Thorough Audits</h3>
              <p className="mt-2 text-gray-300">The smart contracts have undergone thorough security audits by reputable firms.</p>
            </div>
            <div className="flex flex-col items-center text-center">
              <Shield size={48} className="text-pink-400" />
              <h3 className="text-xl font-semibold mt-4">Industry Best Practices</h3>
              <p className="mt-2 text-gray-300">We adhere to industry best practices and implement robust security measures to mitigate risks.</p>
            </div>
            <div className="flex flex-col items-center text-center">
              <Activity size={48} className="text-pink-400" />
              <h3 className="text-xl font-semibold mt-4">User Awareness</h3>
              <p className="mt-2 text-gray-300">Security is paramount, and we encourage users to exercise caution and follow responsible security practices.</p>
            </div>
          </div>
        </div>
      </section>
      <section className="bg-gradient-to-r from-purple-700 to-purple-500 py-36 px-6 text-white text-center">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold mb-6 pb-10">Get Started: Code, Tutorials, and Community</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <div className="bg-white rounded-xl overflow-hidden shadow-md">
              <Image
                src="/tut_1.jpg"
                alt="Developer Coding"
                width={400}
                height={300}
                className="w-full object-cover"
              />
            </div>
            <div className="bg-white rounded-xl overflow-hidden shadow-md">
              <Image
                src="/tut_2.jpg"
                alt="Virtual Learning"
                width={400}
                height={300}
                className="w-full object-cover"
              />
            </div>
            <div className="bg-white rounded-xl overflow-hidden shadow-md">
              <Image
                src="/tut_3.jpg"
                alt="Community Forum"
                width={400}
                height={300}
                className="w-full object-cover"
              />
            </div>
          </div>
          <p className="text-lg pt-10">Join the vibrant community, explore the open-source code, and access comprehensive tutorials to get started with the Options Vault.</p>
        </div>
      </section>
    </div>
  );
}
