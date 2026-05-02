// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// On importe AccessControl d'OpenZeppelin
// C'est une bibliothèque sécurisée et auditée
// qui gère les rôles (qui a le droit de faire quoi)
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title   BudgetRegistry
 * @author  Équipe BudgetOuvert CI — MIABE Hackathon 2026
 * @notice  Registre public et immuable des finances des communes ivoiriennes.
 *          Chaque recette et dépense enregistrée est permanente et vérifiable
 *          par n'importe quel citoyen en temps réel.
 * @dev     Déployé sur Polygon Mumbai (testnet Phase 2)
 *          puis Polygon Mainnet (Phase 3 — finale)
 */
contract BudgetRegistry is AccessControl {

    // =========================================================================
    // RÔLES
    // =========================================================================

    /**
     * @dev COMMUNE_ADMIN est le rôle accordé aux agents municipaux autorisés.
     *      Seuls les wallets ayant ce rôle peuvent enregistrer des transactions.
     *      Le wallet qui déploie le contrat peut accorder/retirer ce rôle.
     *
     *      keccak256 transforme le texte "COMMUNE_ADMIN" en un identifiant
     *      unique de 32 octets — c'est le standard Solidity pour les rôles.
     */
    bytes32 public constant COMMUNE_ADMIN = keccak256("COMMUNE_ADMIN");

    // =========================================================================
    // TYPES DE DONNÉES
    // =========================================================================

    /**
     * @dev TxType définit si une transaction est une recette ou une dépense.
     *      REVENUE = recette (argent entrant dans la commune)
     *      EXPENSE = dépense (argent sortant de la commune)
     */
    enum TxType {
        REVENUE,  // 0
        EXPENSE   // 1
    }

    /**
     * @dev Transaction représente une entrée financière unique d'une commune.
     *      Une fois enregistrée dans le tableau communeTransactions,
     *      elle ne peut JAMAIS être modifiée ni supprimée.
     */
    struct Transaction {
        uint256 id;           // Numéro unique auto-incrémenté
        string  commune;      // Nom officiel de la commune (ex: "Commune Abobo")
        TxType  txType;       // REVENUE ou EXPENSE
        string  category;     // Catégorie (ex: "Infrastructure", "Santé"...)
        uint256 amount;       // Montant en FCFA (nombre entier, pas de décimales)
        uint256 timestamp;    // Date/heure imposée par le réseau Polygon
                              // ⚠️ Personne ne peut falsifier cette valeur
        string  description;  // Libellé de l'opération
        address recorder;     // Adresse wallet de l'agent qui a enregistré
    }

    // =========================================================================
    // STOCKAGE (les données sur la blockchain)
    // =========================================================================

    /**
     * @dev communeTransactions stocke toutes les transactions par commune.
     *      mapping = dictionnaire :  clé (commune) → valeur (liste de transactions)
     *      ex: communeTransactions["Commune Abobo"] → [tx1, tx2, tx3, ...]
     *
     *      "private" signifie qu'on ne peut pas lire directement ce mapping
     *      de l'extérieur — on passe par la fonction getTransactions()
     */
    mapping(string => Transaction[]) private communeTransactions;

    /**
     * @dev communeBalance stocke le solde actuel de chaque commune.
     *      int256 (et non uint256) car le solde peut être négatif
     *      si les dépenses dépassent les recettes enregistrées.
     *
     *      "public" signifie qu'on peut lire directement depuis l'extérieur.
     *      ex: communeBalance["Commune Abobo"] → 47500000 (FCFA)
     */
    mapping(string => int256) public communeBalance;

    /**
     * @dev _transactionCounter est un compteur global qui s'incrémente
     *      à chaque nouvelle transaction — toutes communes confondues.
     *      Il sert à générer des IDs uniques.
     */
    uint256 private _transactionCounter;

    // =========================================================================
    // ÉVÉNEMENTS (signaux émis sur la blockchain)
    // =========================================================================

    /**
     * @dev TransactionRecorded est émis automatiquement à chaque enregistrement.
     *
     *      C'est ce signal que le dashboard citoyen écoute en temps réel.
     *      Dès qu'une commune enregistre une dépense → l'événement est émis
     *      → le dashboard se met à jour instantanément.
     *
     *      "indexed" sur id et commune permet de filtrer rapidement :
     *      ex: "donne-moi tous les événements de la Commune Abobo"
     */
    event TransactionRecorded(
        uint256 indexed id,
        string  indexed commune,
        TxType          txType,
        string          category,
        uint256         amount,
        uint256         timestamp,
        string          description,
        address         recorder
    );

    /**
     * @dev CommuneAdminGranted est émis quand un nouveau wallet reçoit
     *      le rôle COMMUNE_ADMIN (une commune est autorisée).
     */
    event CommuneAdminGranted(address indexed account, address indexed grantedBy);

    /**
     * @dev CommuneAdminRevoked est émis quand un wallet perd
     *      le rôle COMMUNE_ADMIN (accès retiré).
     */
    event CommuneAdminRevoked(address indexed account, address indexed revokedBy);

    // =========================================================================
    // CONSTRUCTEUR
    // =========================================================================

    /**
     * @dev Le constructeur s'exécute UNE SEULE FOIS au moment du déploiement.
     *      Il accorde le rôle DEFAULT_ADMIN_ROLE au wallet qui déploie le contrat.
     *      Ce wallet sera le seul à pouvoir accorder/retirer le rôle COMMUNE_ADMIN.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================================================================
    // FONCTIONS D'ÉCRITURE — Rôle COMMUNE_ADMIN requis
    // =========================================================================

    /**
     * @notice Enregistrer une recette pour une commune.
     *         Seul un wallet avec le rôle COMMUNE_ADMIN peut appeler cette fonction.
     *
     * @param commune     Nom officiel de la commune  (ex: "Commune Abobo")
     * @param category    Catégorie de la recette      (ex: "Transfert État")
     * @param amount      Montant en FCFA              (ex: 50000000)
     * @param description Libellé de l'opération       (ex: "Dotation FDCT T1 2026")
     */
    function recordRevenue(
        string calldata commune,
        string calldata category,
        uint256 amount,
        string calldata description
    )
        external
        onlyRole(COMMUNE_ADMIN)  // Rejeté automatiquement si pas le bon rôle
    {
        // Vérifications de base
        require(amount > 0,              "BudgetRegistry: montant doit etre superieur a 0");
        require(bytes(commune).length > 0,  "BudgetRegistry: nom de commune requis");
        require(bytes(category).length > 0, "BudgetRegistry: categorie requise");

        // Enregistrement interne
        _saveTransaction(commune, TxType.REVENUE, category, amount, description);

        // Mise à jour du solde : on ajoute la recette
        communeBalance[commune] += int256(amount);
    }

    /**
     * @notice Enregistrer une dépense pour une commune.
     *         Seul un wallet avec le rôle COMMUNE_ADMIN peut appeler cette fonction.
     *
     * @param commune     Nom officiel de la commune  (ex: "Commune Abobo")
     * @param category    Catégorie de la dépense     (ex: "Infrastructure")
     * @param amount      Montant en FCFA             (ex: 2500000)
     * @param description Libellé de l'opération      (ex: "Réhabilitation marché central")
     */
    function recordExpense(
        string calldata commune,
        string calldata category,
        uint256 amount,
        string calldata description
    )
        external
        onlyRole(COMMUNE_ADMIN)
    {
        require(amount > 0,              "BudgetRegistry: montant doit etre superieur a 0");
        require(bytes(commune).length > 0,  "BudgetRegistry: nom de commune requis");
        require(bytes(category).length > 0, "BudgetRegistry: categorie requise");

        // Enregistrement interne
        _saveTransaction(commune, TxType.EXPENSE, category, amount, description);

        // Mise à jour du solde : on soustrait la dépense
        communeBalance[commune] -= int256(amount);
    }

    /**
     * @dev Fonction interne partagée par recordRevenue et recordExpense.
     *      "internal" = utilisable seulement à l'intérieur de ce contrat.
     *      Elle crée la Transaction et émet l'événement public.
     */
    function _saveTransaction(
        string calldata commune,
        TxType txType,
        string calldata category,
        uint256 amount,
        string calldata description
    )
        internal
    {
        // Incrémenter le compteur global → ID unique
        uint256 newId = ++_transactionCounter;

        // Créer et sauvegarder la transaction
        // block.timestamp = horodatage imposé par le réseau Polygon
        // msg.sender = adresse du wallet qui appelle la fonction
        communeTransactions[commune].push(Transaction({
            id:          newId,
            commune:     commune,
            txType:      txType,
            category:    category,
            amount:      amount,
            timestamp:   block.timestamp,
            description: description,
            recorder:    msg.sender
        }));

        // Émettre l'événement public → le dashboard reçoit la mise à jour
        emit TransactionRecorded(
            newId,
            commune,
            txType,
            category,
            amount,
            block.timestamp,
            description,
            msg.sender
        );
    }

    // =========================================================================
    // FONCTIONS DE LECTURE — Publiques, sans restriction
    // =========================================================================
    // Ces fonctions sont "view" = elles lisent la blockchain sans modifier
    // quoi que ce soit. Elles sont GRATUITES (pas de frais de gas).

    /**
     * @notice Retourne toutes les transactions d'une commune.
     *         Appelée par le dashboard citoyen et l'app mobile.
     *
     * @param  commune  Nom de la commune (ex: "Commune Abobo")
     * @return          Tableau de toutes les transactions de cette commune
     */
    function getTransactions(string calldata commune)
        external
        view
        returns (Transaction[] memory)
    {
        return communeTransactions[commune];
    }

    /**
     * @notice Retourne le nombre de transactions d'une commune.
     *         Utile pour la pagination côté frontend.
     *
     * @param  commune  Nom de la commune
     * @return          Nombre total de transactions
     */
    function getTransactionCount(string calldata commune)
        external
        view
        returns (uint256)
    {
        return communeTransactions[commune].length;
    }

    /**
     * @notice Retourne le solde actuel d'une commune en FCFA.
     *         Solde = somme des recettes - somme des dépenses
     *
     * @param  commune  Nom de la commune
     * @return          Solde en FCFA (peut être négatif)
     */
    function getBalance(string calldata commune)
        external
        view
        returns (int256)
    {
        return communeBalance[commune];
    }

    /**
     * @notice Retourne le nombre total de transactions
     *         enregistrées sur toutes les communes.
     *
     * @return  Nombre total de transactions
     */
    function getTotalTransactions()
        external
        view
        returns (uint256)
    {
        return _transactionCounter;
    }

    // =========================================================================
    // FONCTIONS D'ADMINISTRATION — Wallet déployeur uniquement
    // =========================================================================

    /**
     * @notice Accorder le rôle COMMUNE_ADMIN à un wallet.
     *         Seul le wallet qui a déployé le contrat peut faire ça.
     *
     * @param account  Adresse MetaMask de l'agent communal à autoriser
     *
     * @dev Dans Remix : Deploy & Run → Deployed Contracts → grantCommuneAdmin
     *      Coller l'adresse MetaMask de la commune → cliquer "transact"
     */
    function grantCommuneAdmin(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(COMMUNE_ADMIN, account);
        emit CommuneAdminGranted(account, msg.sender);
    }

    /**
     * @notice Retirer le rôle COMMUNE_ADMIN à un wallet.
     *         Utile si un agent quitte la mairie ou en cas de compromission.
     *
     * @param account  Adresse MetaMask à désautoriser
     */
    function revokeCommuneAdmin(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(COMMUNE_ADMIN, account);
        emit CommuneAdminRevoked(account, msg.sender);
    }

    /**
     * @notice Vérifier si un wallet a le rôle COMMUNE_ADMIN.
     *
     * @param  account  Adresse à vérifier
     * @return          true si autorisé, false sinon
     */
    function isCommuneAdmin(address account)
        external
        view
        returns (bool)
    {
        return hasRole(COMMUNE_ADMIN, account);
    }
}
