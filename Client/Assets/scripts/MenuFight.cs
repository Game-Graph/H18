using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MenuFight : MonoBehaviour
{
	public MyPet 	myPet;
	public MyPet	enemyPet;
	public Text		money;

	public GameObject buttonProtectHead;
	public GameObject buttonProtectBody;
	public GameObject buttonProtectLegs;

	public GameObject buttonAttackHead;
	public GameObject buttonAttackBody;
	public GameObject buttonAttackLegs;

	public GameObject buttonGiveup;
	public GameObject buttonAttack;
	public GameObject buttonDone;

	public Text	myStatus;
	public Text	enemyStatus;

	public GameObject textWin;
	public GameObject textLost;

	int attackType = 2;
	int protectType = 2;

	RecordPet pet;
	RecordPet petEnemy;

	public void Show(RecordPet pet)
	{
		this.pet = pet;
		myPet.Set (pet);
		buttonAttack.SetActive (false);
		buttonDone.SetActive (false);

		textWin.SetActive (false);
		textLost.SetActive (false);

		UpdateMoney (null);
		Server.GetAccount (UpdateMoney);
		Server.GetEnemy (pet, GetEnemyComplete);

		SetButtonsAttack (attackType);
		SetButtonsProtect (protectType);
	}

	void UpdateMoney(RecordAccount account)
	{
		money.text = "money: " + (account != null ? account.money.ToString () : "---");
	}

	void GetEnemyComplete(RecordPet petEnemy)
	{
		this.petEnemy = petEnemy;
		enemyPet.Set (petEnemy);
		buttonAttack.SetActive (true);
	}

	public void OnAttack()
	{
		Server.Attack (attackType, protectType, OnAttackCallback);
	}

	void OnAttackCallback(RecordFightStep step)
	{
		pet.health = step.fighter_1 == pet.id ? step.health_1 : step.health_2;
		petEnemy.health = step.fighter_1 == petEnemy.id ? step.health_1 : step.health_2;

		myPet.Set (pet);
		enemyPet.Set (petEnemy);

		myStatus.text = GetStatus (step, pet.id);
		enemyStatus.text = GetStatus (step, petEnemy.id);

		if (step.fight_complete) {
			buttonAttack.SetActive (false);
			buttonDone.SetActive (true);
			buttonGiveup.SetActive (false);
			textWin.SetActive (step.winner_id == pet.id);
			textLost.SetActive (step.winner_id != pet.id);
		}
	}

	string GetStatus(RecordFightStep step, string fighter_id)
	{
		string res = "attack: " + GetBodyType ((step.fighter_1 == fighter_id ? step.attack_type_1 : step.attack_type_2));
		res += "\nprotect: " + GetBodyType ((step.fighter_1 == fighter_id ? step.protect_type_1 : step.protect_type_2));
		return res;
	}

	string GetBodyType(int type)
	{
		switch (type) {
		case 1: return "head";
		case 2: return "body";
		case 3: return "body";
		}
		return "---";
	}

	public void OnGiveup()
	{
		Debug.Log ("giveup");
		Server.Giveup (OnAttackCallback);
	}

	public void OnDone()
	{
		MenuMain.Instance.ShowMyPets ();
	}

	void SetButtonSelected(GameObject button, bool selected)
	{
		Color color = selected ? Color.green : Color.white;
		Image img = button.GetComponent<Image> ();
		if (img != null) img.color = color;
	}

	void SetButtonsAttack(int attackType)
	{
		SetButtonsAttack (attackType == 1, attackType == 2, attackType == 3);
	}

	void SetButtonsAttack(bool head, bool body, bool legs)
	{
		SetButtonSelected(buttonAttackHead, head);
		SetButtonSelected(buttonAttackBody, body);
		SetButtonSelected(buttonAttackLegs, legs);
	}

	void SetButtonsProtect(int protectType)
	{
		SetButtonsProtect (protectType == 1, protectType == 2, protectType == 3);
	}

	void SetButtonsProtect(bool head, bool body, bool legs)
	{
		SetButtonSelected(buttonProtectHead, head);
		SetButtonSelected(buttonProtectBody, body);
		SetButtonSelected(buttonProtectLegs, legs);
	}

	public void AttackHead()
	{
		attackType = 1;
		SetButtonsAttack (attackType);
	}

	public void AttackBody()
	{
		attackType = 2;
		SetButtonsAttack (attackType);
	}

	public void AttachLegs()
	{
		attackType = 3;
		SetButtonsAttack (attackType);
	}

	public void ProtectHead()
	{
		protectType = 1;
		SetButtonsProtect (protectType);
	}

	public void ProtectBody()
	{
		protectType = 2;
		SetButtonsProtect (protectType);
	}

	public void ProtectLegs()
	{
		protectType = 3;
		SetButtonsProtect (protectType);
	}
}
