import com.hedera.file.FileCreate;
import com.hedera.file.FileGetContents;
import com.hedera.sdk.account.HederaAccount;
import com.hedera.sdk.common.HederaTransactionAndQueryDefaults;
import com.hedera.sdk.file.HederaFile;
import com.hedera.utilities.ExampleUtilities;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.spec.InvalidKeySpecException;

import static spark.Spark.*;
import com.google.gson.Gson;

import java.util.Vector;

public class MainApp {

    private static RecordAccount myAccount = null;

    private static RecordPet currentEnemy;
    private static RecordPet currentFighter;
    private static RecordFightStep currentFightStep;

    private static long currentBalance;

    private static HederaTransactionAndQueryDefaults hederaQueryDefs;

    private static RecordAccount createDefaultAccount() {
        myAccount = new RecordAccount();
        myAccount.name = "belaze";
        myAccount.money = currentBalance;
        myAccount.pets = new Vector<>();
        return myAccount;
    }

    public static void main(String[] args) throws Exception {

        HederaTransactionAndQueryDefaults txQueryDefaults = new HederaTransactionAndQueryDefaults();

        try {
            txQueryDefaults = ExampleUtilities.getTxQueryDefaults();
        } catch (InvalidKeySpecException e) {
            e.printStackTrace();
        }

        hederaQueryDefs = txQueryDefaults;

        var accountId = txQueryDefaults.payingAccountID;
        HederaAccount account = new HederaAccount(accountId.shardNum, accountId.realmNum, accountId.accountNum);
        account.txQueryDefaults = txQueryDefaults;

        try {
            currentBalance = account.getBalance();
        } catch (Exception e) {
            e.printStackTrace();
        }

        loadFiles(args, txQueryDefaults);

        /*
        InputStream is = MainApp.class.getResourceAsStream("contract.bin");
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[4096];
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();
        byte[] fileContents = buffer.toByteArray();

        HederaFile file = new HederaFile();

        file.txQueryDefaults = txQueryDefaults;


        file = FileCreate.create(file, fileContents);
/*
        // new contract object
        HederaContract contract = new HederaContract();
        // setup transaction/query defaults (durations, etc...)
        contract.txQueryDefaults = txQueryDefaults;

        // create a contract
        contract = ContractCreate.create(contract, file.getFileID(), 0);*/

        port(8080);

        get("/getaccount", (req, res) -> {

            if (myAccount != null) {
                return new Gson().toJson(myAccount);
            } else {
                return new Gson().toJson(createDefaultAccount());
            }
        });

        post("/saveaccount", (request, response) -> {

            var strBody = request.body();
            if (IsNullOrEmpty(strBody)) {
                return "empty";
            } else {
                System.out.println(strBody);
                var gson = new Gson();
                var recAcc = gson.fromJson(strBody, RecordAccount.class);
                if (recAcc != null) {
                    // does nothing
                    return "ok";
                }
                return "ok";
            }
        });

        post("/createpet", (request, response) -> {

            if (myAccount == null) {
                createDefaultAccount();
            }

            var newPet = new RecordPet();
            newPet.attack = getRandom(5, 10);
            newPet.health = getRandom(80, 100);
            newPet.id = String.valueOf(PetSerialNum++);
            newPet.skinId = String.valueOf(getRandom(1, 8));

            newPet.skin = getFileBytes(newPet.skinId, hederaQueryDefs);

            myAccount.pets.add(newPet);
            myAccount.money--;

            return new Gson().toJson(myAccount);
        });

        post("/deletepet", (request, response) -> {
            if (myAccount == null) {
                return new Gson().toJson(createDefaultAccount());
            }

            String id = new Gson().fromJson(request.body(), String.class);
            myAccount.pets.removeIf(pet -> pet.id.equals(id));
            return new Gson().toJson(myAccount);
        });

        post("/getenemy", (request, response) -> {
            if (myAccount == null) {
                createDefaultAccount();
            }

            String id = new Gson().fromJson(request.body(), String.class);

            for(var pet : myAccount.pets) {
                if (pet.id.equals(id)) {
                    currentEnemy = new RecordPet();

                    currentEnemy.id = "999";
                    currentEnemy.skinId = String.valueOf(getRandom(1, 8));
                    currentEnemy.health = (int) (pet.health * (0.9 + 0.2 * Math.random()));
                    currentEnemy.attack = (int) (pet.attack * (0.9 + 0.2 * Math.random()));

                    myAccount.money--;
                    currentFighter = pet;
                    currentFightStep = null;

                    return new Gson().toJson(currentEnemy);
                }
            }

            return "{}";
        });

        post("/attack", (request, response) -> {

            if (currentEnemy == null) {
                return "{}";
            }

            RecordAttack attack = new Gson().fromJson(request.body(), RecordAttack.class);

            var nextFightStep = getNextFightStep(currentFighter, currentEnemy, currentFightStep, attack);
            if (nextFightStep != null) {
                if (nextFightStep.fight_complete && nextFightStep.winner_id.equals(nextFightStep.fighter_1)) {
                    myAccount.money += 2;
                }
                currentFightStep = nextFightStep;
            }

            return new Gson().toJson(currentFightStep);
        });

        get("/giveup", (request, response) -> {

            if (currentEnemy == null) {
                return "{}";
            }

            RecordAttack attack = new Gson().fromJson(request.body(), RecordAttack.class);

            var nextFightStep = getNextFightStep(currentFighter, currentEnemy, currentFightStep, null);
            if (nextFightStep != null) {
                currentFightStep = nextFightStep;
            }

            return new Gson().toJson(currentFightStep);
        });
    }

    private static byte[] getFileBytes(String skinId, HederaTransactionAndQueryDefaults txQueryDefaults) throws Exception {
        var hFile = new HederaFile(0, 0, 1040 + Integer.parseInt(skinId));
        hFile.txQueryDefaults = txQueryDefaults;
        hFile.txQueryDefaults.fileWacl = txQueryDefaults.payingKeyPair;

        return FileGetContents.getBytes(hFile);
    }

    private static void loadFiles(String[] args, HederaTransactionAndQueryDefaults txQueryDefaults) {

        var toLoad = new Vector<String>();
        boolean load = false;
        for(var arg : args) {
            if (arg.equals("--load")) {
                load = true;
            } else if (load) {
                toLoad.add(arg);
            }
        }

        for(var fileName : toLoad) {

            InputStream fileLoadStream = null;

            try {

                fileLoadStream = new FileInputStream(fileName);

                ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                int nRead;
                byte[] data = new byte[4096];
                while ((nRead = fileLoadStream.read(data, 0, data.length)) != -1) {
                    buffer.write(data, 0, nRead);
                }

                buffer.flush();

                byte[] fileContents = buffer.toByteArray();

                HederaFile file = new HederaFile();

                file.txQueryDefaults = txQueryDefaults;
                txQueryDefaults.fileWacl = txQueryDefaults.payingKeyPair;

                Thread.sleep(550);
                file = FileCreate.create(file, fileContents);

                System.out.println("loaded : " + fileName + " " + file.shardNum + "." + file.realmNum + "." + file.fileNum);

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        /*InputStream is = MainApp.class.getResourceAsStream("contract.bin");
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[4096];
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();
        byte[] fileContents = buffer.toByteArray();

        HederaFile file = new HederaFile();

        file.txQueryDefaults = txQueryDefaults;


        file = FileCreate.create(file, fileContents);*/
    }

    private static RecordFightStep getNextFightStep(RecordPet fighter, RecordPet enemy, RecordFightStep prevFightStep, RecordAttack attack) {
        if (prevFightStep != null && prevFightStep.fight_complete) {
            return null;
        }

        int prevEnemyHealth = enemy.health;
        int prevFighterHealth = fighter.health;
        if (prevFightStep != null) {
            prevEnemyHealth = prevFightStep.health_2;
            prevFighterHealth = prevFightStep.health_1;
        }

        var nextTurn = new RecordFightStep();

        if (attack == null) {
            // giveup
            nextTurn.fighter_1 = fighter.id;
            nextTurn.fighter_2 = enemy.id;
            nextTurn.health_1 = 0;
            nextTurn.health_2 = prevEnemyHealth;
            nextTurn.fight_complete = true;
            nextTurn.winner_id = enemy.id;
            nextTurn.attack_type_1 = nextTurn.attack_type_2 = nextTurn.protect_type_1 = nextTurn.protect_type_2 = 0;

        } else {
            int enemyAttackType = getRandom(1, 4);
            int enemyProtectType = getRandom(1, 4);

            nextTurn.attack_type_1 = attack.attackType;
            nextTurn.protect_type_1 = attack.protectType;
            nextTurn.health_1 = enemyAttackType != attack.protectType ? Math.max(0, prevFighterHealth - enemy.attack) : prevFighterHealth;
            nextTurn.fighter_1 = fighter.id;

            nextTurn.attack_type_2 = enemyAttackType;
            nextTurn.protect_type_2 = enemyProtectType;
            nextTurn.health_2 = attack.attackType != enemyProtectType ? Math.max(0, prevEnemyHealth - fighter.attack) : prevEnemyHealth;
            nextTurn.fighter_2 = enemy.id;

            nextTurn.fight_complete = nextTurn.health_1 <= 0 || nextTurn.health_2 <= 0;

            var fighterWins = nextTurn.fight_complete && nextTurn.health_1 > 0;

            if (nextTurn.fight_complete) {
                nextTurn.winner_id = fighterWins ? fighter.id : enemy.id;
            } else {
                nextTurn.winner_id = "";
            }

        }
        return nextTurn;
    }

    private static int PetSerialNum = 1;

    private static int getRandom(int min, int maxEx) {
        return (int) (min + Math.random() * (maxEx - min));
    }

    private static boolean IsNullOrEmpty(String str) {
        return str == null || str.length() == 0;
    }

    public static class RecordPet {
        public String	id;
        public String 	skinId;
        public byte[] skin;
        public int		attack;
        public int		health;
    };

    public static class RecordAccount {
        public String name;
        public long money;
        public Vector<RecordPet> pets;
    }

    public static class RecordAttack {
        public int attackType;
        public int protectType;
    }

    public static class RecordFightStep
    {
        public int attack_type_1;
        public int attack_type_2;
        public int protect_type_1;
        public int protect_type_2;
        public int health_1;
        public int health_2;
        public boolean fight_complete;
        public String winner_id;
        public String fighter_1;
        public String fighter_2;
    }
}
