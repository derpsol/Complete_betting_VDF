async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("Meow");
  const token = await Token.deploy("0xA3D40B9be89e1074309Ed8EFf9F3215F323C8b19", "0x0467036A73Aa793300c11660b6b102a986081dC9");

  console.log("Token address:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });