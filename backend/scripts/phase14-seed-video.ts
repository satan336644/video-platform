const { prisma } = require("../src/prisma");

async function main() {
  const video = await prisma.video.create({
    data: {
      title: "Test",
      description: "Test",
      creatorId: "seed-user-0001",
      status: "CREATED",
      visibility: "PUBLIC",
      category: "amateur",
      tags: ["solo", "hd"],
    },
  });
  console.log("Created video:", video);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
