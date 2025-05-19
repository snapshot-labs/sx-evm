// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";
import { ApeGasVotingStrategy } from "../src/voting-strategies/ApeGasVotingStrategy.sol";
import { VotingTrieParameters, PackedTrieNode } from "../src/voting-strategies/ApeGasVotingStrategy.sol";

contract ApeGasVotingStrategyTest is Test {
    ApeGasVotingStrategy public apeGasVotingStrategy;
    PackedTrieNode[] public nodes;
    string public FORK_URL = "https://rpc.curtis.apechain.com"; // Test data was taken from this curtis
    uint256 public forkId;
    address public herodotusContract = 0x7e22bDFe6f4337790805513872d9A4034f7D8a2D;

    function setUp() public {
        apeGasVotingStrategy = new ApeGasVotingStrategy();
        forkId = vm.createFork(FORK_URL);
        vm.selectFork(forkId);
    }

    function testGetVotingPower1() public {
        address voter = 0xfEDE39f346C1c65d07F2FA476d5f4727A0d7dC43;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90b08b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a05f54df883c446d350a7064d71dc638c7959abb95117dee8e49",
            hex"5d2eaba646f83ba0675559d3e684885ca04118647af84d2ea0367d78d954",
            hex"21f54e42382f5a3d325da0d1f3387eb516adde47c91695f39ae6dbb95551",
            hex"b7b899d11414e9233b89036dfda0ba726a23bd990730606c439038773edb",
            hex"ad9f3b3b8a199b431f05586c973a8e3fa0bd3017f97c8098c65901ff952c",
            hex"eb584e261c52f71436ec603832a9450091186fa02e23a1cfa353becda275",
            hex"a80c99510d5d86b134ef67928b64e7b5502aff519116a07fc3b5340f8358",
            hex"4db91ef1fca9cd65378ae0fac9c4d1c17de8b524f76f717360a0f8ff7f0f",
            hex"918215422bf3a41bb881f78ee6077bae7515f91e096fee090ecca32ba072",
            hex"9ebe4462967ed56a79f5d7e711a77e072d0459cdee94560e70a66e0623c9",
            hex"b3a070afbc5b9491299f2ab02f29e2c8a038dc82e9f860ec213acef73ff0",
            hex"62a426b5a03516d553a5d596c2fb52a91e6fd08a1f5f6a3019db655400ab",
            hex"7edf2c9f28ef4ca0a1273faf4b9512510c57578469a860723662ffea67c3",
            hex"5247b3a62ea0a29548d6a0033db878d86bce5f29a99e407728af174954dc",
            hex"ce2bbe261f760e5717adeff4cba001f87bc7beec726c254940c715ae33d9",
            hex"74182084c22704c30becb82bcb8a9e11a0eed8cd498886147389684f7c76",
            hex"42192fb7fe4fcd104b3786a54d5cab02017f04a04aa745ff2071a6ca9526",
            hex"313fb351b4fe3ccdede45be5e9c9adea19079bad83cf80b90214f90211a0",
            hex"53a8bd49444541ce5d0c5c36e3021c9aaf36749212f20191ae8ed6940b88",
            hex"b3ffa096b046d6685c52a90b85bb974acf70dc3625ee320e4f12271b9fca",
            hex"c4d7bcefa6a0d9a9fc638b3637850dc3289d852627800a5434ab9fed1f6e",
            hex"b6880e777ef92871a04e4681b8bfd0acfe2734a51993f359ea6d460df2a4",
            hex"b422833049577c4d1f0e30a05a4ce4b21a16443726d4b12224eed68659b1",
            hex"0ac166da315b30dfb26079c1be5fa0e9c2b844f13da9c9e95ef7c4c821c9",
            hex"55bd1b771f04eea196f3252e57923b5092a0cff33eaf3967febccd6d1309",
            hex"0ca14fec951915b1cebad5598c92591f7ebf1575a0084b0e2cbd5d5861b8",
            hex"485dad0e0db2e4f79931151ee8203993435c0f4a758637a0689a12afd57b",
            hex"d9202fdbf0c56772d6b3bc9cd36de46f73848cab23ab03d6c1d8a07d6999",
            hex"7a4a397bd9a8fbf9cd617a430c4cab49603d875236f23f65453dc13c99a0",
            hex"21497e24ee5468c84e12dd9b603057890863df39bee1e18f48dad5fdabb5",
            hex"6540a000c74606922e20b024505bc536996b1b18f34339efec3bdfb32f12",
            hex"42775ff124a06ba72f22d6c66887e83dec933bcf02e822f4f28faba71a8a",
            hex"c75b7ef286103a83a0ea33ac847d820f07a5c5adeef70de89f0bbbdf2670",
            hex"c6ad32977d5653f55885d2a027d31426c3079ff3d7d3415350602450a978",
            hex"4c5a2df42d4f03139a69d5341afea01f1b3453d097dee8954da015480fc3",
            hex"bb3896f37a77d04dfc9c8d096a923994bf80b90214f90211a080eed86bdc",
            hex"61bd310d1429513e8e6a942439f94950dd272effcf4aba9b2b2b0fa06817",
            hex"dadd77a3510a1bb4205983d9a5684903698bc1438a805cf8b230d65f30ad",
            hex"a04b9f49f137bff54a38c02abc40283ca690d5883375a254e018f60e708c",
            hex"56f9b6a0457e79cdceac5d1b583136b8f43a7d8384e7f94f3a7c2da9395a",
            hex"78ed8cf65bd3a059144ba6510a94426b6456becd65ebea2111c781c8325c",
            hex"410da1bb8096748c21a017a16f92e95a38dac32491691dffedf3b2e15adc",
            hex"496487f596041b12cdda5568a0666673433ec0601fd86549fd2056acc17b",
            hex"ac31589e14822633c3e2562f6879c1a060da9a86217103c9427120b88000",
            hex"ab6d0ba5fa103b7da88206ff4092a88fac49a0db389335dc5d87dd071e09",
            hex"e147d838678346db3e10fb2ab19bbeab6cc31b2272a0132840899bc5fba1",
            hex"5f3e07d7765a0cc63e2f36b2c38f7badcc0ddb5384d0a70da035dcd54b62",
            hex"305e342b3d00a14a5ddb7d7162ca5efbc9cdda40389fe9454d1896a0e3ab",
            hex"78eeac5ff171c07818163d4cef51094f16652938179059f935cf6d7273a2",
            hex"a050a874276bb0b837d12eb3bf495d14b6c9323cdcb695ed6206865a5474",
            hex"c1b9eba02a1d74692ce045455c89cf53ad310f9962a6ddd4576f85b18bd4",
            hex"9c86e900adfaa03eac9c4b671917e9d79af63cc8eb25cd47a22d77bc3465",
            hex"76de1c57ae4519f059a0003705370c262e2639d8640f2688a81c2e2b6c4f",
            hex"542caa7f0c8bdf1cc32fb1f180b90214f90211a065d0bfe023048a3a7bf8",
            hex"ea87b7cc471a73dcc004a6ca063c77dff084b08309fca07e00f10433dce9",
            hex"f9abac2f32957d37164a80e379bd3233e557d118b445001064a0dd680a3b",
            hex"01a41d4b60f7a280f0f0cdb91d129ab3c35399f75cf1bf71ac349d25a04e",
            hex"e78ba78d98a7c1bd7d22213de3a6db88d8506cc2039cfa109d538fcf53ed",
            hex"c5a0d76e11d74304cf92457ae585c92e565927206f09bc4b884090137a71",
            hex"f0ab364aa0b1f6b39bd29470853122c28726d407779b955ec0d433168836",
            hex"6becf4b4e87a90a0725e3f5b5e28c1160d8768f5362fd4aa3416fa6cd80e",
            hex"4d17d4cb899621c987a2a0e40db4a1e75fab0177fcbba2cb88c3b4ffdf6e",
            hex"eb2d086cf6baed95a83cfad644a077d1dc7b551f5c70ef666acca9790511",
            hex"b4d8dd9d915c9dec7b109eaa4f5fc996a025a40552e12b35e4c2ca62528a",
            hex"f5babc7740ce9757ea343b10ff07659afe5379a035c5c741315d1d6637d0",
            hex"61e9b185d521de6952ef82ab46d676cf671e39f15006a0769ee057bd6e08",
            hex"49d75b8934d945ec4dc2c89c678086dea57f65726105107eb7a0988e4b76",
            hex"16585d9454e9ea2d737321bb92b9453674fd8984279992514938c71da049",
            hex"52a08eb68a5f29897e6575c71f087aa6a9c41c72c595dbd522cd131a1344",
            hex"d1a0f5cb69d02157155d72fb915c303d93ecd44eaaf3aecfa7160625e550",
            hex"629e7596a08967100a30f041e7e527177cd2f1bf80c18ca2a5fbfd099cd0",
            hex"8bd0bb7288f8a780b893f89180a060c64a54c5b2726bd20c873327ccc6ed",
            hex"92ab17e41c9d58babff6c67fb7f5819ba01401f7fec12989ab325492f8ab",
            hex"ded716d86a349eaa099ec1980b1feaad88d4d78080808080808080a060a1",
            hex"82ad274fa6b92fdc0060d61178de6bfff4990b5c5256bff71b49bc21ff0b",
            hex"8080a0aac7cf98345139a879303622738e515366ef948bcc7c8e3930635c",
            hex"65883e3eb68080"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x41BC7Cb8143f21fa6950fee1d89B770020D78057)),
                uint256(uint160(0x0)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x883cf49A530ddaE3EbC9B228398bc5E9B4d2Cfb7)),
                uint256(uint160(0x7116f8b4E2315a17ecF6A6F5970e0ddE2D261C0A)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x26b34a57c9D47FeaA8471bf5D770C38CD81e140F)),
                uint256(uint160(0x394E51C20D68F6662493f34625f415A911a10cCa)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x8887EEaC9E556FbDF82528a4a9819EF32dE73A9C)),
                uint256(uint160(0x166CAC334B2b3c3808bf4628d42BA7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x3DE751b3102deC0C9EBA84cCf03cD579FA6C2ee0)),
                uint256(uint160(0xeeaE81AB4f2BC487c92b312Bba7BcbC9E3Fa6B00)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x707B65f2a5B69A8a284f38eFBD043aa692e389a2)),
                uint256(uint160(0xe2Ec2fA91Ba888C05B9262d560e5Ca763Dfe59e8)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x36EE32cd6e7207C023c502c6432d27D7f0cC740D)),
                uint256(uint160(0x79fC9e632Dc3a0CEdBAfb997C7E7b2873c8B6B0B)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0xFf9D4dE60193d0737edeA76321cc259C4577b2e9)),
                uint256(uint160(0x02DE39f346C1C65D07f2fA476D5F4727a0D7DC43)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000009a)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x12b2040c8b03190485c7,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 0x12b2040c8b03190485c7); // TODO update vp
    }

    function testGetVotingPower2() public {
        address voter = 0xFB58a4b4783B18C099Ef2A95397C437561852B14;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90ac8b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a035f8d355999979a5359c9c9550449372603ac8c521632c2ae0",
            hex"758c75691dff59a0bacbb9855c28f96352e1715373b385dc69a1ac585012",
            hex"e716fa58d0fcfe9a3ef3a0d34a4667714d303b548058a612bc6d83f11b19",
            hex"37a4ae783787c7c66e0f4058b9a0d56776a3bdb78ba7d1bedfc9570e1b46",
            hex"4c77e8422e45a967829db9c41add0589a0d2da1805636d9bd896e9b10ab1",
            hex"da7f7cf36c056a914d5c75d7d46541bd9eddefa0b24f518380759abaea03",
            hex"63e6f00463b49190feea06e15281af375dad459fa43da0c9f667ee99a1b8",
            hex"8a454fbc5d97cb98d6f84497e5fff5b6ce5210d81f75ee07b9a06f54eef3",
            hex"18af920ce57b5ddd6726edbd93486a6a40f0e802cea79059116eebf0a08e",
            hex"eb70e8e2163a9e976644a67bf6d2578eb99da55c22c14b007d67a4e5d8a9",
            hex"cda0007d67206c50d0a7890b9977339800895b9d0d445675221d2a3af215",
            hex"bffefec2a08db6fca70ab68601d107e316bce27f3cfc2fd90aa48f565be8",
            hex"70f9da28396c00a0051597f746e50bc92e7685fa725eff25c38ef62d7042",
            hex"96bac7959c649f59a262a0f445015cf632527091a47e88fd28259ee66b08",
            hex"14da40b50c1a5da67f04e6b72ea0760a9d8cb07cd118266a538c81a51bc2",
            hex"9e740401fd5324695777a6847baa739aa08047785efe47fd25f5c008e6c0",
            hex"74ca1e7e9e50706fe61290fced471b338becefa0773e502ba8c14efd6c94",
            hex"e8eb68b259d64c14983202de967b266e73922798b28d80b90214f90211a0",
            hex"18fe640b1b740aab0ed0d767b1d7e93097ed5560529aece21b05d83e70b1",
            hex"c0a0a0be176d41ece5102d5c7dcc93034ee13bde52da83e4d5666a6f40ce",
            hex"18fe0deaa0a00575dad48f3469713237a119b3323e1041fc2e36663f087a",
            hex"17aaed8447273d5da0ed44c4f2064bda8d6391d8d89b603374fb6d722e1f",
            hex"9dd99dbd0bd04efca5f477a006d5ade6262027e397b0765edb86f3023405",
            hex"17d02de4166338f73118ee0c3dc0a0f0ac996d5460a658a0c973dde0c3d4",
            hex"34c21f20c41afefe2a45202646833c87cea0df1c89f1559602996c5199dd",
            hex"6e086f4894cd0d7edeba014cae204a7166c46bffa0cf7086511b36b99014",
            hex"31842bf1637bff62c226308a19ed8b6ae5508516492de1a0e81952146016",
            hex"4084be7804185d5e0d38eb815f3e18c41268830b81f392493830a05d5680",
            hex"74c4a334e88cb5302e2cbb8228348ea16c04ccce5862dfe52e70f170fea0",
            hex"1b1cb13a973f5e82f708e7d12cd562f4f04eb6fc25ad3de343f93d73dc6a",
            hex"caeca0ceaee05a3fdb1724fb1e50af31e64d577968f27330236b65211ce4",
            hex"7a39f92711a005a329340dd06f8e6c34465554fe311a7765f1c953b1b2bb",
            hex"5e340e3ee9b5d0eea0103da65d2d6efbff1a6966e2a1706b16e7af7a0d21",
            hex"ce59fc1a24d1fbc66dfb2ca0100e8fc05696aeec137fa9000e0f9c3890ee",
            hex"327e10e4b1d8c04f489ef7cdad71a090bcb29ef90a8a0c98cc85ae6e6762",
            hex"b1bf161f0811e6058dea00e613a9054bf580b90214f90211a05a61663079",
            hex"386a58afbef6b2582a4840767cf754803995e31058b20047d94a2ba01b88",
            hex"09e6da8da905162ff657d03ab1884504128e57e6463ae4b766be1fe19513",
            hex"a0035180af102281b4184badab2f8a7c17836dd4dbc3932dc95f0fd63f27",
            hex"11979ba0e8d3d2cb14941b4235c64659c8f0bf822f0e7346171b9740d798",
            hex"dfe36588c2c2a04871c4d51f04c508ec6f3725ad3319f63c04cfa0e2e7b3",
            hex"f48055674a01908a86a08dcbe6841442b7ad3cfa0b1ac4962de3a12b9b66",
            hex"54798ceb0c3b1a48138bb662a0d93dbb41900153607ea4e47741fc43bdf5",
            hex"3ca823fbeb1681155b0698e54d6c89a05786aa709f81f9474339d31c66d9",
            hex"d626ba102bcc7255462bcaa05620c70e1b33a04399440c7b7bb33a7e045e",
            hex"0f745beb42b7218c6c0eab46c73b26199139355542a009edaa34f2adc048",
            hex"030dc97071c2d25ab1f46892ce54d84dbe4e3d4c58fc0bd2a056ffd31d74",
            hex"72bbdaca11ce9351edf5b829aea88441d6c983e3cf3861527f2deba0b603",
            hex"4b318e412782f4904c3af5bad7386b742eca8bcc938edec1bf18a3623216",
            hex"a0ccf23474557bd15eabf079b67d3fa1c339fe3ea24817f8426421fc2777",
            hex"4894f4a0d2440f6f5579e580dcb0b9563d581a9e497d9e35239cb7ed7209",
            hex"2a03e4edc74fa050d071bc4f3d0faf6d8f8ce9f3f99645a682342a6e9233",
            hex"194c849a35b3df4b60a0a380e379ac1d182a08fbe1fefa9b9e962df52a35",
            hex"be2b10bf20a31fd4842e4bd580b90214f90211a021d470d372200e85e644",
            hex"b2474510158f0cdc2447d9fba084c7005b73b3dbdf2aa032fb6cdccffb61",
            hex"fa1e2574aebdb11734c0772d506535457a4ca9f71a164d6cf1a0b5c5ac4a",
            hex"5a2f5f6ac85e73fcda0f03be7238fa5be5b24aefbfe2de8c4a61ccaca03a",
            hex"598c26b76e99ec6713aaaff863a6657724d40ce4a005ee123f67419499c7",
            hex"1aa0b0fa248859f75acc1faec1aed7f4cd8c0667fd9c389d91aa28b5e151",
            hex"99b176d3a09782df658f64ae5bfebadf6fc6d694e699dc21869c7d6c6a57",
            hex"184d1dad912c8ba03639aa7e8be18cb471cfd84bce85627201738c2a6ab8",
            hex"74d145215581d8f64868a03106de0c1e9530b3dc0a95a1f4043df41004c7",
            hex"293df9c2bffd61b5914d12a5d6a0da09099d1a65e66f575258259ab2a5bb",
            hex"2661522ad199537a50bd9c1752f663afa04f947a2b6bb21a49f991030d58",
            hex"54f2bd71b83f4cfb507c5fc62710ac5073a735a0331673450646d0ae24d3",
            hex"58eb481b6bcbed104cb640decdfe2025e1a72cb517bba034f153e93c6dac",
            hex"3f71d35708d5acd88fdea6b710f05c1d40be63e6057f9d43d0a0d6167e3a",
            hex"288a2d157495a713897f768f1fd80f4bb2c0ffff214f3ce822842460a0d7",
            hex"8a233017611eb02fbb4a5299eaf4ce8b1befde0fe6d6ffed2d2a7d1d4ea3",
            hex"1ba0bee9d52f44cc339fab693e62f63d504aebba259c4962790c2085970d",
            hex"264d0bb2a0ce61bb44068f37cfe1c3800fe51affdfda5675bb7ef4ce978d",
            hex"c6859693c842e180b853f851a0e1e15ba543b3b0d4e95ca8091473935d6c",
            hex"12d396a91164e6d23b5c234b4b8d378080808080a0e361f300a9d5a77315",
            hex"b79848fb0746f1a821954f433d7daa1dfe339496a6560c80808080808080",
            hex"808080"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0041bc7cb8143f21fa6950fee1d89b770020d78057)),
                uint256(0x0),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00883cf49a530ddae3ebc9b228398bc5e9b4d2cfb7)),
                uint256(uint160(0x007116f8b4e2315a17ecf6a6f5970e0dde2d261c0a)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0026b34a57c9d47feaa8471bf5d770c38cd81e140f)),
                uint256(uint160(0x00394e51c20d68f6662493f34625f415a911a10cca)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0008887eeac9e556fbdf82528a4a9819ef32de73a9c)),
                uint256(uint160(0x000166cac334b2b3c3808bf4628d42ba7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0003de751b3102dec0c9eba84ccf03cd579fa6c2ee0)),
                uint256(uint160(0x000eeaE81AB4f2BC487c92b312Bba7BcbC9E3Fa6B00)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000707b65f2a5b69a8a284f38efbd043aa692e389a2)),
                uint256(uint160(0x000e2ec2fa91ba888c05b9262d560e5ca763dfe59e8)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00036ee32cd6e7207c023c502c6432d27d7f0cc740d)),
                uint256(uint160(0x00079fc9e632dc3a0cedbafb997c7e7b2873c8b6b0b)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0007ea5121658473b850a617d8ae8812e311fee1dbe)),
                uint256(uint160(0x000649714cc3815aa131272ebd4bcd2291e84136d4f)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000e1d70a029c37aaa4dd2441ccd173be6eb959fd3b)),
                uint256(uint160(0x000158a4b4783b18c099ef2a95397c437561852b14)),
                uint256(0x8000000000000000000000000000000000000000000000000000000000000099)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x6561f823447e888258d6,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 0x6561f823447e888258d6); // TODO update vp
    }

    function testGetVotingPower3() public {
        address voter = 0xf95A37B6C44327c0D2BAB5bA3820F0f8984FBF70;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90a53b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a0839c103af18a372d5a2549b0bdca1dd5c8a8a71198ebe70ea9",
            hex"1f3f00de9c2c46a013e6ef13e6a06e135339a96c78e2c751846df96a4ecc",
            hex"0acf22440f4071db914fa0b602037932aa74cbf034c7944a1b7eff5bf835",
            hex"11af8e9053ee9ee88d115a04eca09d2b12606af9f0c253c61fed887c9c2a",
            hex"7b7b627d0efb8b15c6a6390af41f37cba04cb46ec75e14710d18deb0fd31",
            hex"13eafd4f748dbb958ad81daf82ed70d2c69681a0b9f82c2c672acf0766ca",
            hex"f8a0886787e8c2141224e5f32d6865d7339d161d20a3a0828185ae21a35d",
            hex"9b41dd5dd0097591b2aabb6f1ea6496d7e370eb8dbf9cdc8fca06ef8d35d",
            hex"3b1d7bebb736e040d033e17ce10c69d5e1936de3eb39f638d73f649ba056",
            hex"0c32ccabe54be836301df0c6b7500026b0f911b26c6d21ff5f969664d91f",
            hex"23a0e8af7a14fc1b1e23c16e4419aaf18b25233651f06de40f1f4418d074",
            hex"b30d14b8a06b53fcadb764c8effcdb26f35e3cad2afb132aaee4ca4f10ee",
            hex"236d0e10c7cb9fa07efb841e6b6c1ecb6c7be7e507b8f24e455fbd9aa1ef",
            hex"800470301c69ebb3f9dba018b7091f57ed5e98699b678eb5da593aaac7c5",
            hex"80c7100b6319688e4a638d06cba0cfbaf91ab943c6ec9ea3580419aa8b07",
            hex"83eaaa87b68cb4f9857a7a133029a153a025a1a7a7f61bac0de375da7215",
            hex"5a71922366db3a0117d4873090561330f5b630a027c9f4ae9b274a1ac03f",
            hex"367db8aba1b0a75587dd1a1a577f319abe07bc76c44680b90214f90211a0",
            hex"b99544dcd6faccae4cc35185cec8b03b7fc35aaf5eec702c8f6b5769b713",
            hex"779ea056c1140f0f042f942d0b19c00b95372e13fdd45679ff5c91864480",
            hex"8ed4ce00bfa0bbc8eeaa4ae3bbe01743e8a00418a2a59188900e99a10a5d",
            hex"ddd2aac3938ff673a0d2c6a20549d49e83d485e795121d18f4fac02a5460",
            hex"d95c6eee5d230dae47fb95a047ce1d585c7f52eafa2a7005394ad7a63326",
            hex"efd160ffe52c96ceeeb1b01cc557a040958f77768eb272b96f2a04a0a99f",
            hex"0b420581e8dc89bcb2642df3818a0951d2a0046015b1ffa29e0a4674886a",
            hex"e98aff7fdb9dec0ff62161f61fb028760ca9462fa02adc4b5908d562b175",
            hex"d3e00278edc763cd27010f69e4dcffcb6ed27cf7c6716ea02fe1a91d97cf",
            hex"2bffb01e6e48ee49c52c8d09efd2c13795ee6a9dc96157bf157aa03cd521",
            hex"baa7daec6660d26fb937b3fa91ad8bcea0388b4a2c6111a6b630b25f14a0",
            hex"81c47a1c9b32a19e26bc7fbfb3acd2b95b3f6a6ccb0bdc947ae1520c0515",
            hex"0b1aa0983455b09d44898206ddd7ba81a5f1dd0ea33ad41f8a45af36e086",
            hex"7dbaf5c63ba08eccab3449a18bc2216487ea66212476272974dc3c8cb6ab",
            hex"8373d053bca1e2c6a020133789d09459dd734a94529956c5dd8b9d689387",
            hex"6b8eaaa2b3f53f82223f29a0a8b033d4f45700a8e050fdf4783ad2124bd7",
            hex"ea3c91d3a2bd287bacdb47eba92ea0b064b46a61ae15edfbb30bb82c7a61",
            hex"26d51f4947dbad4c4b88fb3ef1aa7d451d80b90214f90211a06b804a702d",
            hex"317faa44ed1ce41dcb21deceb45b42bee1a5846e9eda94c23bb3fba006e2",
            hex"5f3ce45a0971ac73ff9ae4dda6953153aca94a94c83973eecfc946fec7f3",
            hex"a09357cf5d7a50f353043a4e11d30e3bdde6cb2e9699f67ff9fcfe94b7ae",
            hex"b0fcc6a05e32d9446b8d9c4f0e69ae9e6f86565b14931ff0676bf8645674",
            hex"e32c99bf5ba9a0b095ffc92c3c9aa71a051ffdb070b9a48d56a9a37dff97",
            hex"52b4278f5c5e0a0ce7a002e1b32e4d7827572acd29048dcc0b9bfb797982",
            hex"081f930814d64dd80a5f3beba0f10761a18c3f7783df36500af1979db274",
            hex"0cecb1963d0d156f38b8d402b4c031a0bb0f60e6220c9874d5e7955b7e43",
            hex"8eb699c7139fb0d2e2c734809531cd3d83fba067ec7506187ba57b2936c7",
            hex"2a38e309e6efcd73c3c6f4818461fef0d670f5471ca02066e22903e5f90a",
            hex"ac1440ef8c5e657554220ec8984d62ff228dd24dc9d32624a0e25b1ab89b",
            hex"e85508acf8b4e440aeac6564d7595aeb6e9c97f56e22d76568e901a0d8f7",
            hex"741c3f2daf78bab858c9e18daa1931054c82b24e33d79204fbfd653d7261",
            hex"a02f21af86f401c93d930d763b4f6771e955ce8d1eabd6e615953475c35f",
            hex"193249a0c74108d9ee1d86e3de66a27fba3c923a1986f07a84987440e6e4",
            hex"e244863845f9a0099899eb9e65d5015879fc516b250da87bc4517f65bfd2",
            hex"39299e327d0f86377aa02079b0a0d47749c8426264bdaa64ba946357b3db",
            hex"5e75e18ece172da6b266ebe480b901f4f901f1a09b5149f685c39dd11199",
            hex"6ae811602efd6d923fb4e94744a2e6ef2d6d782869b2a05b84b7edd8da62",
            hex"15c9254dd0d4f6b6fd14b85d8a8efcbaefd888f03bc625bfcba0392e12a6",
            hex"50cffb656189d20ae3314b9a2a00f326e65a677284099ac2d419c413a046",
            hex"1476e7c5115bc8e3a7a2146e35593e04ace5b9710def2b0b4998cdde3676",
            hex"e1a0d2ed52c2bede1d65912e8ab2920c9e5af8920ef24021ffa9ec0b2e9b",
            hex"34accd87a0e8dca19a637e6042012d866cfcafc9533a360191aaa1d4bb01",
            hex"6a1faf6fa02860a083d98d194a186ef9b6ded57376e4546a4025cf973f78",
            hex"8fe4320a6896e132bd51a026ac4c56965daf9b80ea0066e7df913fd7c6ab",
            hex"5b5cda96c5a6332ee25df6fa8ea0fb8389123960ee27a5e033f5288f0fe6",
            hex"ec8add5dfe6de52251e776565ee248cea002fa35bffdb261e1eceb0cfbdd",
            hex"6e7ee614d67a5ec97c465395dd82990d3a67caa0d0436b33cced405774db",
            hex"06a14793cb30e78c0614fef75266f4d7647e7b798752a0b9f89b37dec887",
            hex"15090c56a5c7d7b225019fa7848ea07e72fdd9540ae614a82fa09dbdc02e",
            hex"5b2ed4b21c7e0252df7b84b25ff3be0a0374681bba85b8aaf92305f280a0",
            hex"707ff0d597c247d8e708c1e484bdfecd58473499e15da62e733c7a6f8b6e",
            hex"f1faa04afa578c32d6aa5426a09e4423a48c73757b1d580fd348d4675415",
            hex"10d356dd9880"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0041bc7cb8143f21fa6950fee1d89b770020d78057)),
                uint256(uint160(0x0)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00883cf49a530ddae3ebc9b228398bc5e9b4d2cfb7)),
                uint256(uint160(0x007116f8b4e2315a17ecf6a6f5970e0dde2d261c0a)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00026b34a57c9d47feaa8471bf5d770c38cd81e140f)),
                uint256(uint160(0x000394e51c20d68f6662493f34625f415a911a10cca)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0008887eeac9e556fbdf82528a4a9819ef32de73a9c)),
                uint256(uint160(0x000166cac334b2b3c3808bf4628d42ba7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0003de751b3102dec0c9eba84ccf03cd579fa6c2ee0)),
                uint256(uint160(0x000eeae81ab4f2bc487c92b312bba7bcbc9e3fa6b00)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000707b65f2a5b69a8a284f38efbd043aa692e389a2)),
                uint256(uint160(0x000e2ec2fa91ba888c05b9262d560e5ca763dfe59e8)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00036ee32cd6e7207c023c502c6432d27d7f0cc740d)),
                uint256(uint160(0x00079fc9e632dc3a0cedbafb997c7e7b2873c8b6b0b)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0007ea5121658473b850a617d8ae8812e311fee1dbe)),
                uint256(uint160(0x000649714cc3815aa131272ebd4bcd2291e84136d4f)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00063f8b25b55d6aa8eff28357e03986df3a4b321f4)),
                uint256(uint160(0x01)),
                uint256(0x8000000000000000000000000000000000000000000000000000000000000001)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00f7d852a9a3a861de51ceb2bb6630c3220327b4a1)),
                uint256(uint160(0x00b8ccc9debd5d821f4d7d6ce49c1caa45cb2f482f)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0001fdb80677aa9c3a79e69b3080e1200d99d0a81e0)),
                uint256(uint160(0x0003d4d01b5635a323332f148f363d5e918e16c0fcf)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000460e62934c5dec1a67ba6708975fc1bded62f460)),
                uint256(uint160(0x00001a37b6c44327c0d2bab5ba3820f0f8984fbf70)),
                uint256(0x8000000000000000000000000000000000000000000000000000000000000096)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x583e312f0d46e34c878f6b,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 0x583e312f0d46e34c878f6b);
    }

    function testGetVotingPower4() public {
        address voter = 0xc5398777Ba039b258e59ad9dFf0e2C7652187DAD;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90ae8b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a077d8273cf451027cba7101eea5ec13dde9bba88f6bd36a3583",
            hex"50b54614195f43a0b532e950cbd88aa7de41a9bc8b0fb21cfc7a4e0d3952",
            hex"495cdd061e379855bcf4a016938352e9f0329b28d7e23b56de296e0166c4",
            hex"0d9ab28f4c00eb9cc0b702c7dea0a06fa08960bd61444741dfe48493d89e",
            hex"84b785566ce5f3ed8398f16aad13ba1fa0cc957deb98339155f4c2f3c457",
            hex"46b62355f208778111539f3de7c4be231bc4eea06e90f5e83bb55edffe5f",
            hex"c02d5d21d2263acfde06a1ffe0788c431ca42a43dedaa083372ddceb697b",
            hex"f12141237eddab526fe7b7bc7309085766fffcca9cfbfc3458a0e2ec0aa1",
            hex"46849318221283bb9754ae967ec3317ecff114858edf07ff38e14862a08f",
            hex"dc120b159c172c08df3fd25089ed30a176b4dcce5eefa092ed061ad400d3",
            hex"59a03e122b394df4ee26aae4673b092af992c133948727c8a8ec45b1f39d",
            hex"3a8a812fa0e190d9c6a5eb1d91012fef199231bbb0816cd55c1cc422c08c",
            hex"9af398e88a221fa09f48509679bc7cd38d4cd76e838e9e10e98f9af39ea3",
            hex"ad7cd7876a8de6a6f509a0f8c540da603b9d242daa445cf19169fde62884",
            hex"16dc3e3740fa15e385d89c3ce7a069f04afdbf2ed4040c727daaafbcdd00",
            hex"f543c1f69d29d99e9a6bb89bc762ae24a0a75029869b3f70fad69353381a",
            hex"0ad7470c36dd320cc0ff19e0056c2859c189a9a0fc7cbf8ae8c280874d27",
            hex"d70c3d3953e666f28fd640af62f77e9ac6e0542cec9280b90214f90211a0",
            hex"fe76a6be90c491753a7426c59bf83282fdd919df4e822b02a9536edcd89c",
            hex"1667a0ef56c9f9d5cfeead7b6710d384b4a7294865c9b08688fd3266ff7b",
            hex"d974b3a66da06085dc23ffd7677317a06021f929d92415795a992f725684",
            hex"c54a3bc1ef763281a0e6f96c5eb64d834339a586809fe262c7d817ab40ee",
            hex"cde66ebb218d83c98040d5a0ce074b7070f2ddf94412bc6d09a903f2633b",
            hex"948775baed6d1eda9242718c2744a03485ecc79f363a7406fe64749602c1",
            hex"ba7f8858c1c8886381ed130b9f9c7681d3a08d985e653bbbeb524c984c4b",
            hex"cb3dc15fae87fc44e33f6625de450f1183e68faba02ba0497bba273bbd87",
            hex"9e28481ff52969842294d57e5f880e3976891f0d4fe172a0024038400a4a",
            hex"4dc1e59f9514cefb16656fa426b7e9eb07c443725a423eb03acda008443b",
            hex"8afa9c104e541f1374fde5a2e950224b4a98a0e82e052197250130f1f2a0",
            hex"c7bfab9eb2c112fac1b9b57d87ffcae365cd5b603c18f4e5c43d4e07c246",
            hex"0d01a052db5757058774ac0d98b001f195ad9a109914340c9905ea777893",
            hex"520b0fcd3ea048273103f1bcfcc6370e8584fc92c21380568192e9086f1d",
            hex"3901362d1ed00453a0fafa0cd63303086c80260a645d9bd822263fb7b920",
            hex"cef2c05b15745e9a7e8f31a0db92c2adbe2c7647dad1c50d55d49aa27a03",
            hex"f4e8e933985970a32dde9dcf0c03a0f4c665b7da08e6a68d3c3c08b7b50c",
            hex"1125a4f54f80cc96c84977656b2e0e504680b90214f90211a00341b19b08",
            hex"cdb1ff2c3b3185938894327eaa3d519186a0aaa7e98fb81fa2118ea02512",
            hex"ee54dce2aa80cd0d4c914a633d896203552d1e733b23eaa90a251512cd52",
            hex"a004945743f8333efc1d6a5f97ec8587adfa857528099320c7fdc4375c10",
            hex"0abd4ba044b9baf75fc4d8d83f26c345d6972e06e09f26620eeb71706208",
            hex"c4b3f726a878a0b690346ce96f9078b153636f871276d1dfa6fa67f669ca",
            hex"3f641e0ca9f53094a9a0fcec566373882a12826c8eebf47795958cfa0227",
            hex"febe5861d0df3db0cadaa82aa02e6088daf5be2a072dca6618239fef7d16",
            hex"00533109c7ee35e70099c2a2397b78a076c02178b0f26aaf7981ba20c5d9",
            hex"61035dea8e407e026d5a108547f17b0ba653a000e05fe9b2651c1e4d6477",
            hex"aefe9bb0ec935ccb48529a00794e1b94713cbcb95ca00b56664a96980b9a",
            hex"a0e7ef3ba91d07d502967e6e97013ea99cd237d0aa020e6ca084a2c9f2ef",
            hex"f5b79a08076bf9f37a82251a8ee41c20209fdc40772bf92a691f37a0b4a3",
            hex"b7aa41d39bc2e8d35dcf7f503894b57146cbf958fc3ff8124cb8bc3f6334",
            hex"a0dd0a4ff8717df2c587bdfb12e1abde28dcf79c343fade636a07fce0790",
            hex"137b8ea090adcfe5316d231c79b5194815019c45a044afe940ac7be8945c",
            hex"b7e96e18f777a0a78408da9cce19054e361beb6ac6a65352a46497e34f0a",
            hex"01e5661fb7ba9f1c3da0285c3535fcde3b8a34184a4d76078f599dc765e1",
            hex"c4952b738091391fafee021580b901f4f901f1a04151500cf59c7d6f8426",
            hex"5f9c91561a2f220e1ab89de82c529e3fde4df1a9ffe7a04583d435b54e07",
            hex"c8ecdd3fbb146b7a7d8a6876c89709579fb7e1b1d0863277dea09b10a9e1",
            hex"4411be0e6b4c08d75a2d826b0cd8a7f2668bdb9519efcb31e5e251b5a0cb",
            hex"264010038938ab5f69bb68263d70685e46dd02a565e5c1ba931264d5d056",
            hex"67a005feb756d0fd7dbe6f6e190c9822a340af1e7cf4e8c61895c8b05f2e",
            hex"982f1b6fa0bd21c9154df4a88eeaf7ee56a9c4449b4d74e7530eed818f68",
            hex"7b967b4cb58dffa019f77d5ad24eb4d9b54ec32667712a84d183e11f14b3",
            hex"3c743ab2aecbd180a9eaa0487bf58a5e82737b7209ff44db3e67e2c55315",
            hex"013be1597573f66ae144fef1e2a0a22b7fc8a374068587df0d994a28c219",
            hex"75f0c8ebf856630c778e12452c43ab61a0e7c67c8bb13305e3da5f4d8ed0",
            hex"8a3144a4ef141ee3f5c8c3cfeef75db29909daa038fd2399e41ab5d55988",
            hex"90c865d8218a2982a7816f74620629cfc41dc8908a44a0ee584509a57c88",
            hex"ca4ea4e9b3540ece6eeeb952cbc2621179ed19709e4f81dc2380a0c7cf4f",
            hex"45527d50190e5745209bece7baf609cf77dc204c8ea75a0ac44e45077fa0",
            hex"57d526b753ce10f470fdca2bb7e351b54f50483b90a104d5a9e44221de4f",
            hex"412da0be629a0b43e851be5e0131ecd231fbffadc7ed287f5da0489da1d3",
            hex"fd945dd05380b893f891808080a047d4c8f9af3990cad2c16bd3d4494453",
            hex"53d69b283ece76b5c208344114d3102aa07b7b7d3386750d37e1eccac3b5",
            hex"8bbbf414d17ea0d18a3bb7ef0d06d6c541aaf0a0b3e8abc0a45975edf31a",
            hex"87dcafeefa20c089809355b0dcedcca8ce992d1b73fd8080808080808080",
            hex"80a00110f1acd8df3ffcb4ce90560f5299eaf991830235de25037474c7c3",
            hex"0cc8165680"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00041bc7cb8143f21fa6950fee1d89b770020d78057)),
                uint256(uint160(0x00)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000883cf49a530ddae3ebc9b228398bc5e9b4d2cfb7)),
                uint256(uint160(0x0007116f8b4e2315a17ecf6a6f5970e0dde2d261c0a)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00026b34a57c9d47feaa8471bf5d770c38cd81e140f)),
                uint256(uint160(0x000394e51c20d68f6662493f34625f415a911a10cca)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0008887eeac9e556fbdf82528a4a9819ef32de73a9c)),
                uint256(uint160(0x000166cac334b2b3c3808bf4628d42ba7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00f10492e6c983a9ce50484ab2bb8458c07fad31b0)),
                uint256(uint160(0x00138af14efcaafa74dec02501397d01ec6e12f2ab)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x002ef90cdc0c541d014ad0ab4baa252cccdab16ea8)),
                uint256(uint160(0x00c7ea77c9c7a8f1e050777b11c4de367c9f9cccb5)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0002b0ea05e3adefafb771b46a06424e4d34160663)),
                uint256(uint160(0x00cf31fc2e8d227b34e0da51d534963327c54cd2c3)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00ae1bc99e60009e99b7a279052351a265d80297c1)),
                uint256(uint160(0x00c5d31931949e5520eeac2153774cb9cb262928be)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00d9880d1320d6259c1f811f2d9a9c35e3efd0d98e)),
                uint256(uint160(0x0099b6d03360b1910a98a615ea6332b3f235348d3f)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00085281b90295493c8e660359d9237a2e46eeffc7)),
                uint256(uint160(0x398777ba039b258e59ad9dff0e2c7652187dad)),
                uint256(0x8000000000000000000000000000000000000000000000000000000000000098)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0xdedc6bdef9bfc1b67f3,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 0xdedc6bdef9bfc1b67f3);
    }

    function testGetVotingPower5() public {
        address voter = 0xc5398777BA039b258e59Ad9dFf0e2C7652187aAA;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90ac8b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a04745e5ea8d900007c26ed5f6d1ee0ccb6d546b17e7d85c6ed2",
            hex"9240083f2c0958a0781b88ff326b4521119074ab49a6e23497ed0db4d14c",
            hex"02e15f73f665f9b63ea3a00519653aaf4f0f1bf1a2f042ab1f486743f34b",
            hex"934214702120d45a4f9843900ea03a2cea92fb8d9c99598bee4c583b3603",
            hex"6fba3a13785e8fb1e84f50e0bfa16b1ba025ab1386acccf059deafb57a62",
            hex"0b4d5d2177e38f026cc742d110acf5a321fa7da06db82868e63b065cce6c",
            hex"2bd78dc6659fb87684c4fdc7cc7018e7c873431fe214a0c3fd2e688c3d26",
            hex"f43478a4d3b2638f5b6020fe158a33ce1cad43c2c4ed1c138ba02ad62871",
            hex"cb10a861919f382afdb0c96e26cd46e4172de1ce2554e441d9cb2b02a0bf",
            hex"3f44367a82a5416713376610822b27aa3ed2be06bdf8d7485b3668b5039d",
            hex"53a09a8049a470d43ab7b3a84e9b4729cc2d829c0c35fad5255019c7d521",
            hex"670b8ab4a0f53d8a2675c075a0a8d0405fb616844ab18884d4632bf64f2e",
            hex"a84b585db21314a0bb34aca5e56b8ce2ad309b1ac0286553e5ee6d1c197a",
            hex"86236d4ef0246ba01898a0af3fe43cc7517d7fc0950d3730684a1b6def75",
            hex"6f85f07681bbb35cb24dba9978a00115bd17fbed889ccdd8f6c12c7e225e",
            hex"515405f51738a7c8bc37fd8ac105ee20a0d510b6dd7e9b359afc17fbf0a0",
            hex"53ecd5e73bc071e14d3d4d68553fda804f18e5a004481d11a5930ec07977",
            hex"ef81c937ccbca60d1c746ed6f2773dcace886f0bba5980b90214f90211a0",
            hex"68b71b5ae51e5a8972bab8cb9ab45c66c2f4449f4f985826078005bc60c8",
            hex"6f76a06bc8571996ea5dc8b5f07190277409f66382adb0aa6dfcf28a25ac",
            hex"f18bb44aa1a03237e30516fd3d55ee06a1812150f5eaa54c5f0f042bc674",
            hex"73a072fdedb2931ca07ed380119e0c257d3f73d49d96e2791a350a830990",
            hex"12542d562a156f9b90115fa05815a6eef958c107cebe27a63a2bae4bc82a",
            hex"a3bbac6eee507aef023efb1a22c0a0b077ace6f16d94109c8ad15b551ea3",
            hex"4c95e563c665267c2311bd62eff4bd309ea0b34b99e717b326359bdc1fc3",
            hex"060ab18f87d8e55dd37ed7c025e52c7f8ccac03aa0fe452d0d24ac1de3aa",
            hex"1428c229446f15fccd875f27f5d3c02e53443da7c2cab2a0b4ab960e1602",
            hex"69e3800a90e4a40f6f24557950c9477d5fb309aa018f629eed58a0cf88de",
            hex"ee7805ae8ffe31459f932f2bf0c2d4931842271f0f05c5c96e6252b2b5a0",
            hex"fe95cc7e0eadfd6e8934a8c7fa81eac0f1feea236cc79fb3a99fd51dd815",
            hex"5cdda08bdf4f38f12cc1ef20e50b632033cd26aa89b5a129375d77d1380d",
            hex"0784edcd04a00872f1ed198bb1a8ed958c09e647f0c42e85c6a39a0606a0",
            hex"0881e5daaa1ff398a00c043d9a87782d15e6f61fd07864ef68744c6edc21",
            hex"ac362c770d3932e747d29aa044e206f4d00dacd308f6f767c233c9eeed94",
            hex"a22cccddac0c1068ab00d03e4e56a095abc1d1459c3d889439e46c893bcf",
            hex"25b6b0b2c924c90235dfdc7ef301b49a1f80b90214f90211a023b18754b8",
            hex"56e8e8686667879c5d90eb7e3e6b04cc0c1fff3a6add51afde3b9ea0150f",
            hex"c995400978b1967ca50ae18abf6345ace48180b8871a1f0b8070a2314f56",
            hex"a0dd8f7db4d3e4caa7d1972229b16fa39e43ba07489c49bc60c9af140195",
            hex"ab603ba0e473771ca47ec1f1709b91b6661f072c51bda2ff8f68fce36c8c",
            hex"d936db07c151a03067e430823cfdd7a125c65cea74c69e1967c82ee1c3b2",
            hex"e4e18d4bf4c28ce2e0a05bfb60747fb7eedd1b880f2b84832b29948218b8",
            hex"d0bc7aaf4f17d582defbb5fea052c093a8d5fc08b02c7a1668f45b25ab51",
            hex"fc6f5e07b17d524cb3b0675e5a96e1a0db9cea3e717e8a500a72a8e883cf",
            hex"17ad5236f2b8b228589c5f6478f9aa6858a9a03bc67cbb716972185e438e",
            hex"d15e7cdadffa83e83a145f0b4279a362830ed863c1a076f09876378a401c",
            hex"84b71b842ed2eebd1d04f87d2c9789177667a9ad1acdd634a0f24b0b29b9",
            hex"94e1a14fd5d0ee04c3d3ced8527f247f86df428f97f9e932f79040a0878c",
            hex"9a2788472f88cdbc0c9e552ad5cb38a3b203e925da94ff31318194e66400",
            hex"a04a07610692221844d6558a4e3f292d822388bc3b192a924e386a195c6f",
            hex"a8dd93a0481fa6ab8b8aad7e909a2f3ce784a79283baedc804f94b5f0114",
            hex"38f0eadaf10ea0bc272e2ae6f9a838e1bf4ec0e10e1c0722ff8837efae5a",
            hex"e5e23b0a166c0a4c91a04bd7e440cf05b1a8bb6da7ae8f25f9ab884e5dfd",
            hex"06113d0665fa6e8505d89ff180b90214f90211a0bf55c6113de637cb067e",
            hex"3bd4b1cb59cfe604c085200127e89e43dab323b27443a07fc175e412d331",
            hex"bbe5499134408a9fe64bdbe3df1c842864a7319beedacaa13ca017ebec08",
            hex"67839f1d02425cf154c4a81282d123b1a869aa7fc1bd7445aeca1e9da022",
            hex"5600f237dec26f148fc67a9a7f6c143f02b6c64e8a6c70682b6c8d6f9d18",
            hex"fba0c03717b0d7191560158639526e2c84bb89773ec5f356d0138ca7ba7b",
            hex"41fbb540a07525e14ae764a59d3992fc95053d3715758ef5640cf410b3dd",
            hex"ff95652bf40d5da0c59f418fcad30fcf8865988dbbb8b497e36966d43602",
            hex"cda3f8f386ac914a8f29a0defe9d63e78ad1b3103e900e0d80868e587dd7",
            hex"c69628b69bf33fbc744d768eb3a0d7ec88b0ca0aa31dc744b2ba0de6631d",
            hex"9227aaf1d23ca23bb06feb8e694d7cb1a07132cb3e9ac5dcd5534ea232bc",
            hex"58c03e7b14ba648c02748c6d588c3a41496b84a0ce14e79793d208725f73",
            hex"7bd66ddb680c3b85c2b1a6d21f02f1dd5da3752b948da0d686571304f11b",
            hex"b20cbd33313ae0d4962e228a81173f7f485c0e8ab244bf21fba090ae4269",
            hex"b891cc83219b1ec152df48cb0f6db1f7e41d218acd5cd2402716b975a0da",
            hex"df45aed2f77c89a7d6b21a3fb4e4c33579d4e8394699ab26d68e6d8f6124",
            hex"a1a04cdb9641b109c9ce6fcdb981a260dafb4587b3f763d728a1b2feec35",
            hex"c1c39ee5a05e46535bbd3ee8dd24429d4d763268a953c76abdf886551402",
            hex"060e792be4ca1480b853f8518080808080808080a0ffbd2bd5051e113281",
            hex"ea614a3367efd98af3637eb3549a1e886bb7e678867f10808080808080a0",
            hex"02b63d3f3d207ed8b40444f130c4bef827aa4db880157dc808a09bb5964f",
            hex"cc1680"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0041bc7cb8143f21fa6950fee1d89b770020d78057)),
                uint256(0x0),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000883cf49a530ddae3ebc9b228398bc5e9b4d2cfb7)),
                uint256(uint160(0x0007116f8b4e2315a17ecf6a6f5970e0dde2d261c0a)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00026b34a57c9d47feaa8471bf5d770c38cd81e140f)),
                uint256(uint160(0x000394e51c20d68f6662493f34625f415a911a10cca)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0008887eeac9e556fbdf82528a4a9819ef32de73a9c)),
                uint256(uint160(0x000166cac334b2b3c3808bf4628d42ba7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000f10492e6c983a9ce50484ab2bb8458c07fad31b0)),
                uint256(uint160(0x000138af14efcaafa74dec02501397d01ec6e12f2ab)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0002ef90cdc0c541d014ad0ab4baa252cccdab16ea8)),
                uint256(uint160(0x000c7ea77c9c7a8f1e050777b11c4de367c9f9cccb5)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x0002b0ea05e3adefafb771b46a06424e4d34160663)),
                uint256(uint160(0x000cf31fc2e8d227b34e0da51d534963327c54cd2c3)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x000ae1bc99e60009e99b7a279052351a265d80297c1)),
                uint256(uint160(0x000c5d31931949e5520eeac2153774cb9cb262928be)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00d9880d1320d6259c1f811f2d9a9c35e3efd0d98e)),
                uint256(uint160(0x0099b6d03360b1910a98a615ea6332b3f235348d3f)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x00085281b90295493c8e660359d9237a2e46eeffc7)),
                uint256(uint160(0x0000398777ba039b258e59ad9dff0e2c7652187dad)),
                uint256(0x8000000000000000000000000000000000000000000000000000000000000098)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x0,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint256 votingPower = apeGasVotingStrategy.getVotingPower(blockNumber, voter, params, userParams);

        assertEq(votingPower, 0x0);
    }

    function testInvalidBlockNumber() public {
        // Taken from testGetVotingPower1
        address voter = 0xfEDE39f346C1c65d07F2FA476d5f4727A0d7dC43;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90b08b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a05f54df883c446d350a7064d71dc638c7959abb95117dee8e49",
            hex"5d2eaba646f83ba0675559d3e684885ca04118647af84d2ea0367d78d954",
            hex"21f54e42382f5a3d325da0d1f3387eb516adde47c91695f39ae6dbb95551",
            hex"b7b899d11414e9233b89036dfda0ba726a23bd990730606c439038773edb",
            hex"ad9f3b3b8a199b431f05586c973a8e3fa0bd3017f97c8098c65901ff952c",
            hex"eb584e261c52f71436ec603832a9450091186fa02e23a1cfa353becda275",
            hex"a80c99510d5d86b134ef67928b64e7b5502aff519116a07fc3b5340f8358",
            hex"4db91ef1fca9cd65378ae0fac9c4d1c17de8b524f76f717360a0f8ff7f0f",
            hex"918215422bf3a41bb881f78ee6077bae7515f91e096fee090ecca32ba072",
            hex"9ebe4462967ed56a79f5d7e711a77e072d0459cdee94560e70a66e0623c9",
            hex"b3a070afbc5b9491299f2ab02f29e2c8a038dc82e9f860ec213acef73ff0",
            hex"62a426b5a03516d553a5d596c2fb52a91e6fd08a1f5f6a3019db655400ab",
            hex"7edf2c9f28ef4ca0a1273faf4b9512510c57578469a860723662ffea67c3",
            hex"5247b3a62ea0a29548d6a0033db878d86bce5f29a99e407728af174954dc",
            hex"ce2bbe261f760e5717adeff4cba001f87bc7beec726c254940c715ae33d9",
            hex"74182084c22704c30becb82bcb8a9e11a0eed8cd498886147389684f7c76",
            hex"42192fb7fe4fcd104b3786a54d5cab02017f04a04aa745ff2071a6ca9526",
            hex"313fb351b4fe3ccdede45be5e9c9adea19079bad83cf80b90214f90211a0",
            hex"53a8bd49444541ce5d0c5c36e3021c9aaf36749212f20191ae8ed6940b88",
            hex"b3ffa096b046d6685c52a90b85bb974acf70dc3625ee320e4f12271b9fca",
            hex"c4d7bcefa6a0d9a9fc638b3637850dc3289d852627800a5434ab9fed1f6e",
            hex"b6880e777ef92871a04e4681b8bfd0acfe2734a51993f359ea6d460df2a4",
            hex"b422833049577c4d1f0e30a05a4ce4b21a16443726d4b12224eed68659b1",
            hex"0ac166da315b30dfb26079c1be5fa0e9c2b844f13da9c9e95ef7c4c821c9",
            hex"55bd1b771f04eea196f3252e57923b5092a0cff33eaf3967febccd6d1309",
            hex"0ca14fec951915b1cebad5598c92591f7ebf1575a0084b0e2cbd5d5861b8",
            hex"485dad0e0db2e4f79931151ee8203993435c0f4a758637a0689a12afd57b",
            hex"d9202fdbf0c56772d6b3bc9cd36de46f73848cab23ab03d6c1d8a07d6999",
            hex"7a4a397bd9a8fbf9cd617a430c4cab49603d875236f23f65453dc13c99a0",
            hex"21497e24ee5468c84e12dd9b603057890863df39bee1e18f48dad5fdabb5",
            hex"6540a000c74606922e20b024505bc536996b1b18f34339efec3bdfb32f12",
            hex"42775ff124a06ba72f22d6c66887e83dec933bcf02e822f4f28faba71a8a",
            hex"c75b7ef286103a83a0ea33ac847d820f07a5c5adeef70de89f0bbbdf2670",
            hex"c6ad32977d5653f55885d2a027d31426c3079ff3d7d3415350602450a978",
            hex"4c5a2df42d4f03139a69d5341afea01f1b3453d097dee8954da015480fc3",
            hex"bb3896f37a77d04dfc9c8d096a923994bf80b90214f90211a080eed86bdc",
            hex"61bd310d1429513e8e6a942439f94950dd272effcf4aba9b2b2b0fa06817",
            hex"dadd77a3510a1bb4205983d9a5684903698bc1438a805cf8b230d65f30ad",
            hex"a04b9f49f137bff54a38c02abc40283ca690d5883375a254e018f60e708c",
            hex"56f9b6a0457e79cdceac5d1b583136b8f43a7d8384e7f94f3a7c2da9395a",
            hex"78ed8cf65bd3a059144ba6510a94426b6456becd65ebea2111c781c8325c",
            hex"410da1bb8096748c21a017a16f92e95a38dac32491691dffedf3b2e15adc",
            hex"496487f596041b12cdda5568a0666673433ec0601fd86549fd2056acc17b",
            hex"ac31589e14822633c3e2562f6879c1a060da9a86217103c9427120b88000",
            hex"ab6d0ba5fa103b7da88206ff4092a88fac49a0db389335dc5d87dd071e09",
            hex"e147d838678346db3e10fb2ab19bbeab6cc31b2272a0132840899bc5fba1",
            hex"5f3e07d7765a0cc63e2f36b2c38f7badcc0ddb5384d0a70da035dcd54b62",
            hex"305e342b3d00a14a5ddb7d7162ca5efbc9cdda40389fe9454d1896a0e3ab",
            hex"78eeac5ff171c07818163d4cef51094f16652938179059f935cf6d7273a2",
            hex"a050a874276bb0b837d12eb3bf495d14b6c9323cdcb695ed6206865a5474",
            hex"c1b9eba02a1d74692ce045455c89cf53ad310f9962a6ddd4576f85b18bd4",
            hex"9c86e900adfaa03eac9c4b671917e9d79af63cc8eb25cd47a22d77bc3465",
            hex"76de1c57ae4519f059a0003705370c262e2639d8640f2688a81c2e2b6c4f",
            hex"542caa7f0c8bdf1cc32fb1f180b90214f90211a065d0bfe023048a3a7bf8",
            hex"ea87b7cc471a73dcc004a6ca063c77dff084b08309fca07e00f10433dce9",
            hex"f9abac2f32957d37164a80e379bd3233e557d118b445001064a0dd680a3b",
            hex"01a41d4b60f7a280f0f0cdb91d129ab3c35399f75cf1bf71ac349d25a04e",
            hex"e78ba78d98a7c1bd7d22213de3a6db88d8506cc2039cfa109d538fcf53ed",
            hex"c5a0d76e11d74304cf92457ae585c92e565927206f09bc4b884090137a71",
            hex"f0ab364aa0b1f6b39bd29470853122c28726d407779b955ec0d433168836",
            hex"6becf4b4e87a90a0725e3f5b5e28c1160d8768f5362fd4aa3416fa6cd80e",
            hex"4d17d4cb899621c987a2a0e40db4a1e75fab0177fcbba2cb88c3b4ffdf6e",
            hex"eb2d086cf6baed95a83cfad644a077d1dc7b551f5c70ef666acca9790511",
            hex"b4d8dd9d915c9dec7b109eaa4f5fc996a025a40552e12b35e4c2ca62528a",
            hex"f5babc7740ce9757ea343b10ff07659afe5379a035c5c741315d1d6637d0",
            hex"61e9b185d521de6952ef82ab46d676cf671e39f15006a0769ee057bd6e08",
            hex"49d75b8934d945ec4dc2c89c678086dea57f65726105107eb7a0988e4b76",
            hex"16585d9454e9ea2d737321bb92b9453674fd8984279992514938c71da049",
            hex"52a08eb68a5f29897e6575c71f087aa6a9c41c72c595dbd522cd131a1344",
            hex"d1a0f5cb69d02157155d72fb915c303d93ecd44eaaf3aecfa7160625e550",
            hex"629e7596a08967100a30f041e7e527177cd2f1bf80c18ca2a5fbfd099cd0",
            hex"8bd0bb7288f8a780b893f89180a060c64a54c5b2726bd20c873327ccc6ed",
            hex"92ab17e41c9d58babff6c67fb7f5819ba01401f7fec12989ab325492f8ab",
            hex"ded716d86a349eaa099ec1980b1feaad88d4d78080808080808080a060a1",
            hex"82ad274fa6b92fdc0060d61178de6bfff4990b5c5256bff71b49bc21ff0b",
            hex"8080a0aac7cf98345139a879303622738e515366ef948bcc7c8e3930635c",
            hex"65883e3eb68080"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x41BC7Cb8143f21fa6950fee1d89B770020D78057)),
                uint256(uint160(0x0)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x883cf49A530ddaE3EbC9B228398bc5E9B4d2Cfb7)),
                uint256(uint160(0x7116f8b4E2315a17ecF6A6F5970e0ddE2D261C0A)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x26b34a57c9D47FeaA8471bf5D770C38CD81e140F)),
                uint256(uint160(0x394E51C20D68F6662493f34625f415A911a10cCa)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x8887EEaC9E556FbDF82528a4a9819EF32dE73A9C)),
                uint256(uint160(0x166CAC334B2b3c3808bf4628d42BA7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x3DE751b3102deC0C9EBA84cCf03cD579FA6C2ee0)),
                uint256(uint160(0xeeaE81AB4f2BC487c92b312Bba7BcbC9E3Fa6B00)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x707B65f2a5B69A8a284f38eFBD043aa692e389a2)),
                uint256(uint160(0xe2Ec2fA91Ba888C05B9262d560e5Ca763Dfe59e8)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x36EE32cd6e7207C023c502c6432d27D7f0cC740D)),
                uint256(uint160(0x79fC9e632Dc3a0CEdBAfb997C7E7b2873c8B6B0B)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0xFf9D4dE60193d0737edeA76321cc259C4577b2e9)),
                uint256(uint160(0x02DE39f346C1C65D07f2fA476D5F4727a0D7DC43)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000009a)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x12b2040c8b03190485c7,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        uint32 invalidBlockNumber = blockNumber - 1;
        vm.expectRevert("Voting trie root mismatch");
        apeGasVotingStrategy.getVotingPower(invalidBlockNumber, voter, params, userParams);
    }

    function testInvalidVoter() public {
        // Taken from testGetVotingPower1
        address voter = 0xfEDE39f346C1c65d07F2FA476d5f4727A0d7dC43;
        uint32 blockNumber = 17399780;
        bytes memory params = abi.encode(herodotusContract);

        bytes memory accountProof = bytes.concat(
            hex"f90b08b90214f90211a0340dee4db579b33a6543b006ce7eeedfafcc37c4",
            hex"9536e6ee1de3248f07353608a02967e5718b7badad667242b8f795a31bb3",
            hex"8195b3671a6aeb96c6879d1f79d46ca09252f6e3b753b709e624029f2126",
            hex"831dc0f4afe09c921a57d822d63449c82549a04158faca3e4a6046945344",
            hex"d8232e6a51948cbf55516326b87397b2e88d92c979a0af4b119689c74102",
            hex"abb287b5ee5212dc90ebfcd6fa9413c3eb7913ec40b20915a017c80dfbf2",
            hex"6c007ea7087506724c255c4a96803ec1a109e6e1662e528799a771a0deb2",
            hex"4ee389b3f77cfc8a5c470510077be3df19fdc9627bf00fd88022ffb277de",
            hex"a0309bf8cd5b7186aac2f73b2073512e36614b20dcc4d283cce9fe9252a8",
            hex"fd3694a01e6a0459174499c5b767ac32ef4eb35a982530031131a228fdc0",
            hex"83d0a98d8fb3a0b81be524575b8099629cd00acabaf09f2b6f155c4ce678",
            hex"0a13d76b3724818f1fa0c7d7bf7c85f453d1b3495c39ad77dc7e7ee473e9",
            hex"ab62f1ebb3ba4e61178f3172a01a9da48f1603c5f90a87ed4c127cd6a6a3",
            hex"baa7376409c0753401717817b5fc9da0e16ac29ee18602566bf7a4c3b542",
            hex"f1a3557ffadbf0c194a6df27596d10cd8938a0ae8b29a0e275a2b5a473fa",
            hex"12c5afdeb12d7ebc8cda30a4a4dee973a8bbbc7d30a006ced3c015df743e",
            hex"82a480733ac858b31492d0339fc29719d7e3740762dc402fa0975dcd745a",
            hex"4d9fda86c96a1f214c725c632ecd2a8f0de07f49b5feb119de657e80b902",
            hex"14f90211a05f54df883c446d350a7064d71dc638c7959abb95117dee8e49",
            hex"5d2eaba646f83ba0675559d3e684885ca04118647af84d2ea0367d78d954",
            hex"21f54e42382f5a3d325da0d1f3387eb516adde47c91695f39ae6dbb95551",
            hex"b7b899d11414e9233b89036dfda0ba726a23bd990730606c439038773edb",
            hex"ad9f3b3b8a199b431f05586c973a8e3fa0bd3017f97c8098c65901ff952c",
            hex"eb584e261c52f71436ec603832a9450091186fa02e23a1cfa353becda275",
            hex"a80c99510d5d86b134ef67928b64e7b5502aff519116a07fc3b5340f8358",
            hex"4db91ef1fca9cd65378ae0fac9c4d1c17de8b524f76f717360a0f8ff7f0f",
            hex"918215422bf3a41bb881f78ee6077bae7515f91e096fee090ecca32ba072",
            hex"9ebe4462967ed56a79f5d7e711a77e072d0459cdee94560e70a66e0623c9",
            hex"b3a070afbc5b9491299f2ab02f29e2c8a038dc82e9f860ec213acef73ff0",
            hex"62a426b5a03516d553a5d596c2fb52a91e6fd08a1f5f6a3019db655400ab",
            hex"7edf2c9f28ef4ca0a1273faf4b9512510c57578469a860723662ffea67c3",
            hex"5247b3a62ea0a29548d6a0033db878d86bce5f29a99e407728af174954dc",
            hex"ce2bbe261f760e5717adeff4cba001f87bc7beec726c254940c715ae33d9",
            hex"74182084c22704c30becb82bcb8a9e11a0eed8cd498886147389684f7c76",
            hex"42192fb7fe4fcd104b3786a54d5cab02017f04a04aa745ff2071a6ca9526",
            hex"313fb351b4fe3ccdede45be5e9c9adea19079bad83cf80b90214f90211a0",
            hex"53a8bd49444541ce5d0c5c36e3021c9aaf36749212f20191ae8ed6940b88",
            hex"b3ffa096b046d6685c52a90b85bb974acf70dc3625ee320e4f12271b9fca",
            hex"c4d7bcefa6a0d9a9fc638b3637850dc3289d852627800a5434ab9fed1f6e",
            hex"b6880e777ef92871a04e4681b8bfd0acfe2734a51993f359ea6d460df2a4",
            hex"b422833049577c4d1f0e30a05a4ce4b21a16443726d4b12224eed68659b1",
            hex"0ac166da315b30dfb26079c1be5fa0e9c2b844f13da9c9e95ef7c4c821c9",
            hex"55bd1b771f04eea196f3252e57923b5092a0cff33eaf3967febccd6d1309",
            hex"0ca14fec951915b1cebad5598c92591f7ebf1575a0084b0e2cbd5d5861b8",
            hex"485dad0e0db2e4f79931151ee8203993435c0f4a758637a0689a12afd57b",
            hex"d9202fdbf0c56772d6b3bc9cd36de46f73848cab23ab03d6c1d8a07d6999",
            hex"7a4a397bd9a8fbf9cd617a430c4cab49603d875236f23f65453dc13c99a0",
            hex"21497e24ee5468c84e12dd9b603057890863df39bee1e18f48dad5fdabb5",
            hex"6540a000c74606922e20b024505bc536996b1b18f34339efec3bdfb32f12",
            hex"42775ff124a06ba72f22d6c66887e83dec933bcf02e822f4f28faba71a8a",
            hex"c75b7ef286103a83a0ea33ac847d820f07a5c5adeef70de89f0bbbdf2670",
            hex"c6ad32977d5653f55885d2a027d31426c3079ff3d7d3415350602450a978",
            hex"4c5a2df42d4f03139a69d5341afea01f1b3453d097dee8954da015480fc3",
            hex"bb3896f37a77d04dfc9c8d096a923994bf80b90214f90211a080eed86bdc",
            hex"61bd310d1429513e8e6a942439f94950dd272effcf4aba9b2b2b0fa06817",
            hex"dadd77a3510a1bb4205983d9a5684903698bc1438a805cf8b230d65f30ad",
            hex"a04b9f49f137bff54a38c02abc40283ca690d5883375a254e018f60e708c",
            hex"56f9b6a0457e79cdceac5d1b583136b8f43a7d8384e7f94f3a7c2da9395a",
            hex"78ed8cf65bd3a059144ba6510a94426b6456becd65ebea2111c781c8325c",
            hex"410da1bb8096748c21a017a16f92e95a38dac32491691dffedf3b2e15adc",
            hex"496487f596041b12cdda5568a0666673433ec0601fd86549fd2056acc17b",
            hex"ac31589e14822633c3e2562f6879c1a060da9a86217103c9427120b88000",
            hex"ab6d0ba5fa103b7da88206ff4092a88fac49a0db389335dc5d87dd071e09",
            hex"e147d838678346db3e10fb2ab19bbeab6cc31b2272a0132840899bc5fba1",
            hex"5f3e07d7765a0cc63e2f36b2c38f7badcc0ddb5384d0a70da035dcd54b62",
            hex"305e342b3d00a14a5ddb7d7162ca5efbc9cdda40389fe9454d1896a0e3ab",
            hex"78eeac5ff171c07818163d4cef51094f16652938179059f935cf6d7273a2",
            hex"a050a874276bb0b837d12eb3bf495d14b6c9323cdcb695ed6206865a5474",
            hex"c1b9eba02a1d74692ce045455c89cf53ad310f9962a6ddd4576f85b18bd4",
            hex"9c86e900adfaa03eac9c4b671917e9d79af63cc8eb25cd47a22d77bc3465",
            hex"76de1c57ae4519f059a0003705370c262e2639d8640f2688a81c2e2b6c4f",
            hex"542caa7f0c8bdf1cc32fb1f180b90214f90211a065d0bfe023048a3a7bf8",
            hex"ea87b7cc471a73dcc004a6ca063c77dff084b08309fca07e00f10433dce9",
            hex"f9abac2f32957d37164a80e379bd3233e557d118b445001064a0dd680a3b",
            hex"01a41d4b60f7a280f0f0cdb91d129ab3c35399f75cf1bf71ac349d25a04e",
            hex"e78ba78d98a7c1bd7d22213de3a6db88d8506cc2039cfa109d538fcf53ed",
            hex"c5a0d76e11d74304cf92457ae585c92e565927206f09bc4b884090137a71",
            hex"f0ab364aa0b1f6b39bd29470853122c28726d407779b955ec0d433168836",
            hex"6becf4b4e87a90a0725e3f5b5e28c1160d8768f5362fd4aa3416fa6cd80e",
            hex"4d17d4cb899621c987a2a0e40db4a1e75fab0177fcbba2cb88c3b4ffdf6e",
            hex"eb2d086cf6baed95a83cfad644a077d1dc7b551f5c70ef666acca9790511",
            hex"b4d8dd9d915c9dec7b109eaa4f5fc996a025a40552e12b35e4c2ca62528a",
            hex"f5babc7740ce9757ea343b10ff07659afe5379a035c5c741315d1d6637d0",
            hex"61e9b185d521de6952ef82ab46d676cf671e39f15006a0769ee057bd6e08",
            hex"49d75b8934d945ec4dc2c89c678086dea57f65726105107eb7a0988e4b76",
            hex"16585d9454e9ea2d737321bb92b9453674fd8984279992514938c71da049",
            hex"52a08eb68a5f29897e6575c71f087aa6a9c41c72c595dbd522cd131a1344",
            hex"d1a0f5cb69d02157155d72fb915c303d93ecd44eaaf3aecfa7160625e550",
            hex"629e7596a08967100a30f041e7e527177cd2f1bf80c18ca2a5fbfd099cd0",
            hex"8bd0bb7288f8a780b893f89180a060c64a54c5b2726bd20c873327ccc6ed",
            hex"92ab17e41c9d58babff6c67fb7f5819ba01401f7fec12989ab325492f8ab",
            hex"ded716d86a349eaa099ec1980b1feaad88d4d78080808080808080a060a1",
            hex"82ad274fa6b92fdc0060d61178de6bfff4990b5c5256bff71b49bc21ff0b",
            hex"8080a0aac7cf98345139a879303622738e515366ef948bcc7c8e3930635c",
            hex"65883e3eb68080"
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x41BC7Cb8143f21fa6950fee1d89B770020D78057)),
                uint256(uint160(0x0)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000005b)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x883cf49A530ddaE3EbC9B228398bc5E9B4d2Cfb7)),
                uint256(uint160(0x7116f8b4E2315a17ecF6A6F5970e0ddE2D261C0A)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x26b34a57c9D47FeaA8471bf5D770C38CD81e140F)),
                uint256(uint160(0x394E51C20D68F6662493f34625f415A911a10cCa)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x8887EEaC9E556FbDF82528a4a9819EF32dE73A9C)),
                uint256(uint160(0x166CAC334B2b3c3808bf4628d42BA7458a9f2687)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x3DE751b3102deC0C9EBA84cCf03cD579FA6C2ee0)),
                uint256(uint160(0xeeaE81AB4f2BC487c92b312Bba7BcbC9E3Fa6B00)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x707B65f2a5B69A8a284f38eFBD043aa692e389a2)),
                uint256(uint160(0xe2Ec2fA91Ba888C05B9262d560e5Ca763Dfe59e8)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0x36EE32cd6e7207C023c502c6432d27D7f0cC740D)),
                uint256(uint160(0x79fC9e632Dc3a0CEdBAfb997C7E7b2873c8B6B0B)),
                uint256(0x0)
            )
        );

        nodes.push(
            PackedTrieNode(
                uint256(uint160(0xFf9D4dE60193d0737edeA76321cc259C4577b2e9)),
                uint256(uint160(0x02DE39f346C1C65D07f2fA476D5F4727a0D7DC43)),
                uint256(0x800000000000000000000000000000000000000000000000000000000000009a)
            )
        );

        VotingTrieParameters memory votingTrieParameters = VotingTrieParameters({
            accountProof: accountProof,
            account: voter,
            committmentHasDelegated: false,
            committmentVotingPower: 0x12b2040c8b03190485c7,
            nodes: nodes
        });
        bytes memory userParams = abi.encode(votingTrieParameters);

        address invalidVoter = address(1337);

        vm.expectRevert(abi.encodeWithSelector(ApeGasVotingStrategy.InvalidVoter.selector));
        apeGasVotingStrategy.getVotingPower(blockNumber, invalidVoter, params, userParams);
    }
}
