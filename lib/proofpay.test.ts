import { describe, expect, it } from "vitest";
import { Status, statusLabel, statusTone } from "./proofpay";
describe("ProofPay status mapping",()=>{it("matches Solidity enum order",()=>{expect(statusLabel(Status.OPEN)).toBe("Open");expect(statusLabel(Status.SUBMITTED)).toBe("Submitted");expect(statusLabel(Status.REJECTED)).toBe("Rejected");});it("provides a tone for every status",()=>Object.values(Status).forEach(v=>expect(statusTone(v)).toBeTruthy()));});
