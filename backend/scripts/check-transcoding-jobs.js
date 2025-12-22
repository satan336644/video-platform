require("dotenv").config();
const { PrismaClient } = require("../node_modules/.prisma/client");

const prisma = new PrismaClient();

(async () => {
  const rows = await prisma.transcodingJob.findMany({
    orderBy: { createdAt: "desc" },
    take: 10,
  });
  console.log(rows);
  await prisma.$disconnect();
})().catch((err) => {
  console.error(err);
  prisma.$disconnect().catch(() => {});
  process.exit(1);
});
