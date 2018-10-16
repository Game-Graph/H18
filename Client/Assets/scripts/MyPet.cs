using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MyPet : MonoBehaviour
{
	public Image pic;
	public Text		textId;
	public Text 	textAttack;
	public Text		textHealth;
	public GameObject	menu;

	RecordPet pet = null;

	public void Set(RecordPet pet)
	{
		this.pet = pet;
		textId.text = pet != null ? pet.id : "none";
		textAttack.text = pet != null ? pet.attack.ToString() : "none";
		textHealth.text = pet != null ? pet.health.ToString() : "none";
		pic.sprite = pet != null ? pet.GetSkin () : null;

		if (menu != null)
			menu.SetActive (false);
	}

	public void OnTap()
	{
		if (menu != null) menu.SetActive (!menu.activeSelf);
	}

	public void OnFight()
	{
		MenuMain.Instance.ShowFight (pet);
	}

	public void OnDelete()
	{
		Server.DeletePet (pet.id, OnDeleteComplete);
	}

	public void OnDeleteComplete(RecordAccount account)
	{
		MenuPets.Instance.Show ();
	}
}
