using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class RecordAccount
{
	public string name;
	public uint money;
	public List<RecordPet> pets;

	string PetsToString()
	{
		if (pets == null)
			return "NULL";

		string res = "";
		for (int i = 0; i < pets.Count; i++) {
			if (i > 0)
				res += ",";
			res += pets [i].ToString ();
		}

		return res;
	}

	new public string ToString()
	{
		return "{name=" + name + ", pets=[" + PetsToString() + "]}";
	}
}
