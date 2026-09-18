"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useWatchContractEvent } from "wagmi";
import { proofPayAbi } from "@/lib/proofpay";
import { proofPayAddress } from "@/lib/chain";

export function ChainSync() {
  const queryClient = useQueryClient();
  const onLogs = () => void queryClient.invalidateQueries();
  useWatchContractEvent({ address: proofPayAddress, abi: proofPayAbi, onLogs, enabled: !!proofPayAddress });
  return null;
}
