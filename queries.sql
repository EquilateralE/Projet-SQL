-- Requetes demandées :

-- Liste de l'ensemble des agences
SELECT 
    agence.id_agence, 
    ville.nom_ville
FROM ville
JOIN agence ON ville.id_ville = agence.id_ville;

--Liste de l'ensemble du personnel technique de l'agence de Bordeaux
SELECT nom
FROM agent
JOIN agent_tech ON agent_tech.id_agent = agent.id_agent
JOIN agence ON agence.id_agence = agent.id_agence
JOIN ville ON ville.id_ville = agence.id_ville
WHERE ville.nom_ville = 'Bordeaux';

--Nombre total des capteurs déployers
SELECT COUNT(id_capteur)
FROM capteur;

--Liste des rapport publiés entre 2018 et 2022
SELECT 
    ref_rapport,
    date_rapport
FROM rapport
WHERE date_rapport BETWEEN '2018-01-01' AND '2022-12-31';

-- Afficher les concentrations de CH4 (en ppm) dans les régions :
-- « Ile-de-France », « Bretagne » et « Occitanie » en mai et juin 2023
SELECT 
    r.nom_region,
    v.nom_ville,
    d.date_donnee,
    d.mesure
FROM donnee d
JOIN capteur c ON d.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
JOIN ville v ON c.id_ville = v.id_ville
JOIN region r ON v.id_region = r.id_region
WHERE r.nom_region IN ('Île-de-France', 'Bretagne', 'Occitanie')
AND g.sigle = 'CH4'
AND d.date_donnee BETWEEN '2023-05-01' AND '2023-06-30'
AND d.mesure IS NOT NULL
AND d.mesure != 0
ORDER BY d.date_donnee ASC;

-- Liste des noms des agents techniques maintenant des capteurs 
-- concernant les gaz à effet de serre provenant de l’industrie (GESI)
SELECT a.nom, prenom
FROM agent a
JOIN agent_tech at ON a.id_agent = at.id_agent
JOIN capteur c ON at.id_agent = c.id_agent
JOIN gaz g ON c.id_gaz = g.id_gaz
JOIN type t ON g.id_type = t.id_type
WHERE t.nom_type = 'GESI';

-- Titres et dates des rapports concernant des concentrations de CH4
-- classés par ordre anti-chronologique
SELECT DISTINCT r.ref_rapport AS titre, r.date_rapport
FROM rapport r
JOIN donnee d ON d.id_rapport = r.id_rapport
JOIN capteur c ON d.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
WHERE g.sigle = 'CH4'
ORDER BY r.date_rapport DESC;


-- Afficher le mois où la concentration de HFC 
-- a été la moins importante pour chaque région
SELECT 
    r.nom_region,
    MONTH(d.date_donnee) AS mois,
    MIN(d.mesure) AS concentration_min
FROM donnee d
JOIN capteur c ON d.id_capteur = c.id_capteur
JOIN gaz g ON c.id_gaz = g.id_gaz
JOIN ville v ON c.id_ville = v.id_ville
JOIN region r ON v.id_region = r.id_region
WHERE g.nom_gaz = 'HFC'
  AND d.mesure IS NOT NULL
  AND d.mesure != 0
GROUP BY r.nom_region, mois
ORDER BY r.nom_region, mois ASC;


-- Afficher la moyenne des concentrations (en ppm) 
-- dans la région « Ile-de-France » en 2020, pour chaque gaz étudié
SELECT 
    g.nom_gaz,
    AVG(d.mesure) AS concentration_moyenne,
    COUNT(*) AS nombre_mesures
FROM donnee d
JOIN capteur c ON d.id_capteur = c.id_capteur
JOIN ville v ON c.id_ville = v.id_ville
JOIN region r ON v.id_region = r.id_region
JOIN gaz g ON c.id_gaz = g.id_gaz
WHERE r.nom_region = 'Île-de-France'
  AND d.date_donnee BETWEEN '2020-01-01' AND '2020-12-31'
  AND d.mesure IS NOT NULL
  AND d.mesure != 0
GROUP BY g.nom_gaz
ORDER BY concentration_moyenne DESC;

-- Taux de productivité des agents administratifs de l'agence de Toulouse
-- (le taux est calculé en nombre de rapports écrits par mois en moyenne, sur la durée de leur contrat)
SELECT 
    a.nom AS nom_agent, 
    a.prenom AS prenom_agent,
    COUNT(r.id_rapport) / 
        (TIMESTAMPDIFF(MONTH, a.prise_poste, CURDATE()) + 1) AS taux_productivite
FROM agent_admin aa
JOIN agent a ON aa.id_agent = a.id_agent
JOIN agence ag ON a.id_agence = ag.id_agence
JOIN ville v ON ag.id_ville = v.id_ville
LEFT JOIN rapport r ON aa.id_agent = r.id_agent
WHERE v.nom_ville = 'Toulouse'
AND a.prise_poste IS NOT NULL
GROUP BY a.id_agent, a.nom, a.prenom, a.prise_poste
ORDER BY taux_productivite DESC;

-- Pour un gaz donné, liste des rapports contenant des données qui le concernent
-- (on doit pouvoir donner le nom du gaz en paramètre)
DELIMITER $$
CREATE PROCEDURE rapports_par_gaz(IN gaz_nom VARCHAR(50))
BEGIN
    SELECT r.ref_rapport, r.date_rapport, d.mesure
    FROM rapport r
    JOIN donnee d ON r.id_rapport = d.id_rapport
    JOIN capteur c ON d.id_capteur = c.id_capteur
    JOIN gaz g ON c.id_gaz = g.id_gaz
    WHERE g.sigle = gaz_nom 
    AND d.mesure IS NOT NULL
    AND d.mesure != 0
    ORDER BY r.date_rapport DESC;
END$$
DELIMITER ;

CALL rapports_par_gaz('CO2');

-- Liste des régions dans lesquelles il y a plus de capteurs que de personnel d’agence
SELECT r.nom_region
FROM region r
JOIN ville v ON r.id_region = v.id_region
LEFT JOIN agence a ON a.id_ville = v.id_ville
LEFT JOIN agent ag ON ag.id_agence = a.id_agence
LEFT JOIN capteur c ON c.id_ville = v.id_ville
GROUP BY r.id_region, r.nom_region
HAVING COUNT(DISTINCT c.id_capteur) > COUNT(DISTINCT ag.id_agent);

-- Création de l'utilisateur demandé --
CREATE USER 'utilisateur_normal'@'localhost' IDENTIFIED BY 'motdepasse123';

GRANT SELECT, INSERT ON cleardata.* TO 'utilisateur_normal'@'localhost';
CREATE USER 'admin_cleardata'@'localhost' IDENTIFIED BY 'adminsecure123';

GRANT ALL PRIVILEGES ON cleardata.* TO 'admin_cleardata'@'localhost' WITH GRANT OPTION;
