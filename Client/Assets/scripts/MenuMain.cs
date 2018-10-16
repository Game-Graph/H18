using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class MenuMain : MonoBehaviour
{
	public static MenuMain Instance;

	public MenuLogin	menuLogin;
	public MenuPets		menuPets;
	public MenuFight	menuFight;

	public List<Sprite> skins;

	void Start()
	{
		Instance = this;
		menuLogin.gameObject.SetActive (true);
		menuPets.gameObject.SetActive (false);
		menuFight.gameObject.SetActive (false);
	}

	public void ShowMyPets()
	{
		menuLogin.gameObject.SetActive (false);
		menuPets.gameObject.SetActive (true);
		menuFight.gameObject.SetActive (false);

		menuPets.Show ();
	}

	public void ShowFight(RecordPet pet)
	{
		menuLogin.gameObject.SetActive (false);
		menuPets.gameObject.SetActive (false);
		menuFight.gameObject.SetActive (true);

		menuFight.Show (pet);
	}
}
