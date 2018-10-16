using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

public class MenuPets : MonoBehaviour
{
	public static MenuPets Instance;

	public MyPet 		myPetProto;
	public GameObject	loading;
	public Text 		money;

	List<MyPet> myPets;

	void Start()
	{
		Instance = this;
	}

	public void Show(RecordAccount account = null)
	{
		myPetProto.gameObject.SetActive (false);

		if (loading != null)
			loading.SetActive (true);
		
		if (myPets != null) {
			foreach (var pet in myPets) {
				Debug.Log ("delete " + pet.name);
				Destroy (pet.gameObject);
			}
			myPets.Clear ();
		}

		if (account != null) GetAccountComplete (account);
		else Server.GetAccount (GetAccountComplete);
	}

	void GetAccountComplete(RecordAccount account)
	{
		List<RecordPet> pets = account != null ? account.pets : null;
		if (loading != null)
			loading.SetActive (false);

		if (pets != null)
			for (int i = 0; i < pets.Count; i++) {
				MyPet myPet = Instantiate (myPetProto) as MyPet;
				myPet.gameObject.SetActive (true);
				myPet.Set (pets [i]);
				myPet.transform.SetParent (myPetProto.transform.parent);
				myPet.name = pets [i].id;

				if (myPets == null)
					myPets = new List<MyPet> ();

				myPets.Add (myPet);

				Debug.Log ("create " + myPet.name);
			}

		money.text = "money: " + (account != null ? account.money.ToString () : "---");
	}

	public void CreatePet()
	{
		Server.CreatePet (CreatePetComplete);
	}

	void CreatePetComplete(RecordAccount account)
	{
		Show (account);
	}
}
