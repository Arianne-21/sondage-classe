import os
import tempfile
import unittest

os.environ.pop("DATABASE_URL", None)
import app as sondage


class StatisticsTests(unittest.TestCase):
    def setUp(self):
        self.db_dir = tempfile.TemporaryDirectory()
        os.environ["SQLITE_PATH"] = os.path.join(self.db_dir.name, "test.db")
        sondage._pret = False
        self.client = sondage.app.test_client()

    def tearDown(self):
        sondage._pret = False
        self.db_dir.cleanup()

    def test_api_returns_live_sorted_percentages_and_zero_choices(self):
        form_data = {
            "prenom": "Ariane",
            "filiere": "Informatique",
            "niveau": "Débutant",
            "techno": "Python",
            "avis": "",
        }
        self.client.post("/", data=form_data)
        form_data["prenom"] = "Camille"
        self.client.post("/", data=form_data)
        form_data.update(prenom="Noa", techno="JavaScript")
        self.client.post("/", data=form_data)

        response = self.client.get("/api/statistiques")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["total"], 3)
        self.assertEqual(
            response.json["classements"]["technos"],
            [
                {"nom": "Python", "nombre": 2, "pourcentage": 66.7},
                {"nom": "JavaScript", "nombre": 1, "pourcentage": 33.3},
                {"nom": "Autre", "nombre": 0, "pourcentage": 0},
                {"nom": "Java", "nombre": 0, "pourcentage": 0},
                {"nom": "PHP", "nombre": 0, "pourcentage": 0},
            ],
        )
        self.assertEqual(
            response.json["classements"]["niveaux"][0],
            {"nom": "Débutant", "nombre": 3, "pourcentage": 100.0},
        )
        results = self.client.get("/resultats").get_data(as_text=True)
        self.assertIn("66.7%", results)
        self.assertIn("33.3%", results)

    def test_empty_database_returns_zero_percentages(self):
        total, classement = sondage.statistiques_technos()

        self.assertEqual(total, 0)
        self.assertTrue(all(nombre == pourcentage == 0 for _, nombre, pourcentage in classement))


if __name__ == "__main__":
    unittest.main()
