import { BountyView } from "@/components/bounty-view";

export default async function BountyPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <BountyView id={id} />;
}
