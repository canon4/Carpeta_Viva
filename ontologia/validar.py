"""Valida core.ttl y ejemplo-sintetico.ttl y ejecuta las consultas de competencia con rdflib.
Uso: python ontologia/validar.py   (requiere: pip install rdflib)"""
import re
from pathlib import Path

from rdflib import Graph, RDF, OWL

DIR = Path(__file__).resolve().parent
ESPERADO = {
    "documentos_salud_menor_001": 1,
    "menores_con_asignacion_vigente_en_hogar_01": 2,
    "menores_sin_informe_psicosocial_reciente": 1,
    "hogares_por_zona": 1,
}


def main() -> None:
    g = Graph()
    g.parse(DIR / "core.ttl")
    clases = set(g.subjects(RDF.type, OWL.Class)) - {s for s in g.subjects(RDF.type, OWL.Class) if not str(s).startswith("http://www.sistemaicbf#")}
    assert len(clases) == 8, f"se esperaban 8 clases, hay {len(clases)}"
    g.parse(DIR / "ejemplo-sintetico.ttl")
    bloques = re.split(r"^### (\w+)\n", (DIR / "consultas.rq").read_text(encoding="utf-8"), flags=re.M)[1:]
    for nombre, consulta in zip(bloques[0::2], bloques[1::2]):
        filas = list(g.query(consulta))
        assert len(filas) == ESPERADO[nombre], f"{nombre}: {len(filas)} filas, se esperaban {ESPERADO[nombre]}"
        print(f"ok {nombre}: {len(filas)}")
    print(f"ontología válida: {len(clases)} clases, {len(g)} tripletas")


if __name__ == "__main__":
    main()
