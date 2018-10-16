pragma solidity ^0.4.0;

import './utils/safe-math.sol';
import './iface.sol';

interface IPlatform {
  function mintToken(address _owner) external payable returns(uint);
}

interface IGame {
  // function name() external view returns(string);
  function transferOwnership(address _newOwner) external;
}

contract PlatformBase is Erc165 {
  bytes4 public constant INTERFACE_SIGNATURE =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('mintToken()')) ^
    bytes4(keccak256('registerGame(uint)')) ^
    bytes4(keccak256(''));
}

contract GameBase is Erc165 {
  // Game name
  string public constant name = '';
  // Erc165 interface signature
  bytes4 public constant INTERFACE_SIGNATURE =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('homepage()')) ^
    bytes4(keccak256('support()')) ^
    bytes4(keccak256('upgrade(address)')) ^
    bytes4(keccak256('transferOwnership(address)')) ^
    bytes4(keccak256('reset(uint)')) ^
    // bytes4(keccak256('increaseLevel(uint)')) ^
    // bytes4(keccak256('decreaseLevel(uint)')) ^
    bytes4(keccak256('increaseParam(uint, string, uint)')) ^
    bytes4(keccak256('decreaseParam(uint, string, uint)')) ^
    // bytes4(keccak256('addAsset(uint itemId)')) ^
    // bytes4(keccak256('removeAsset(uint itemId)')) ^
    bytes4(keccak256(''));
}

contract EngineBase is Erc165 {
  bytes4 public constant INTERFACE_SIGNATURE =
    bytes4(keccak256('version()')) ^
    bytes4(keccak256(''));

  /// Engine version
  uint public constant version = 0;
}

contract Game is GameBase, IGame {
  // Types ---------------------------------------------------------------------

  // State ---------------------------------------------------------------------

  /// Game name
  string public constant name = 'The Game';
  /// Game homepage url
  string public constant homepage = 'https://publisher.io/the-game';
  /// Game support page url
  string public constant support = 'https://publisher.io/the-game/help';
  /// Game engine address
  address public engine;
  /// Game owner address
  address public owner;
  /// Game platform address
  address public platform;
  /// Token params
  mapping(uint => mapping(string => uint)) params_;
  mapping(uint => bool) appliedTokens_;

  constructor(address _owner, address _platform)
    public
  {
    require(_owner != address(0), 'owner_addr');
    require(_platform != address(0), 'platform_addr');

    owner = _owner;
    platform = _platform;
  }

  // Events
  //
  event TransferredTo(address owner);
  event Upgraded(address newEngine, uint version);

  // Modifiers ---------------------------------------------------------------

  modifier engineOnly() {
    require(msg.sender == engine, 'engineOnly');
    _;
  }

  modifier ownerOnly() {
    require(msg.sender == owner, 'ownerOnly');
    _;
  }

  modifier platformOnly() {
    require(msg.sender == platform, 'platformOnly');
    _;
  }

  modifier tokenOwnerOnly(uint _tokenId) {
    require(Platform(platform).ownerOf(_tokenId) == msg.sender, 'tokenOwnerOnly');
    _;
  }

  modifier isEngineOnly(address _addr) {
    require(isEngine(_addr), 'isEngineOnly');
    _;
  }

  // Methods -------------------------------------------------------------------

  function isEngine(address _addr)
    internal
    pure
    returns(bool)
  {
    return Engine(_addr).supportsInterface(bytes4(0x54fd4d50fc));
  }

  function upgrade(address _newEngine)
    public
  {
    require(_newEngine != address(0), 'newEngine_addr');
    Engine e = Engine(_newEngine);

    require(e.supportsInterface(bytes4(0x54fd4d50fc)), 'HashgraphEngine_interface');
    require(e.version() > Engine(engine).version(), 'newEngine_version');

    engine = _newEngine;

    emit Upgraded(_newEngine, e.version());
  }

  function getParam(uint _tokenId, string _param)
    public
    view
    returns(uint)
  {
    return params_[_tokenId][_param];
  }

  function setParam(uint _tokenId, string _param, uint _value)
    public
    view
    returns(uint)
  {
    return params_[_tokenId][_param] = _value;
  }

  function transferOwnership(address _newOwner)
    public
  {
    require(_newOwner != address(0), 'newOwner_addr');

    owner = _newOwner;

    emit TransferredTo(_newOwner);
  }

  function burnToken(address _tokenId) {
    Platform(platform).burnToken(_tokenId);
  }

  function applyToken(uint _tokenId)
    public
    platformOnly
  {
    appliedTokens_[_tokenId] = true;
  }

  function releaseToken(uint _tokenId)
    public
    tokenOwnerOnly(_tokenId)
  {
    require(appliedTokens_[_tokenId], 'appliedToken');

    Platform(platform).stopPlay(_tokenId);
    appliedTokens_[_tokenId] = false;
  }
}

contract Engine is EngineBase {
  /// Engine name
  string public constant name = '';
  /// Engine version
  uint public constant version = 0;
  /// Engine owner
  address public owner;
  /// Linked engine game
  address public game;

  constructor(address _owner, address _game)
    public
  {
    require(_owner != address(0), 'owner_addr');
    require(_game != address(0), 'game_addr');

    owner = _owner;
    game = _game;
  }

  modifier ownerOnly() {
    require(msg.sender == owner, 'ownerOnly');
    _;
  }
}

contract Platform is PlatformBase, IPlatform {
    // Extension ---------------------------------------------------------------
    using SafeMath for uint;
    // Types -------------------------------------------------------------------

    // Constants ---------------------------------------------------------------
    string public constant name = 'The Platform';

    // State -------------------------------------------------------------------

    /// Contract address
    address owner_;
    /// Persona token ownership mapping
    mapping(uint => address) internal ownership_;
    mapping(uint => uint) internal ownIndexes_;
    mapping(address => uint[]) internal ownTokens_;
    mapping(uint => address) internal tokenGame_;
    mapping(address => bool) internal games_;
    /// Games which was played by token
    mapping(uint => mapping(address => bool)) playedGames_;
    mapping(uint => address[]) playedGamesList_;
    /// All token's games in chronological order
    mapping(uint => mapping(address => bool)) activeGames_;
    // Current persona token counter
    uint i_ = 1;
    /// New persona mint fee
    uint mintFee_;
    /// Game registration fee
    uint regFee_;
    /// Game registration status
    mapping(address => bool) regStatus_;

    // Lifetime ----------------------------------------------------------------
    constructor(address _owner, uint _mintFee, uint _regFee)
      public
    {
      require(_owner != address(0), 'owner_addr');

      owner_ = _owner;
      mintFee_ = _mintFee;
      regFee_ = _regFee;
    }

    // Events ------------------------------------------------------------------
    event TokenOwnership(uint tokenId, address newOwner);
    // Modifiers ---------------------------------------------------------------

    modifier tokenOwnerOnly(uint _tokenId) {
      require(ownership_[_tokenId] == msg.sender, 'tokenOwnerOnly');
      _;
    }

    modifier tokenGameOnly(uint _tokenId) {
      require(tokenGame_[_tokenId] == msg.sender, 'tokenGameOnly');
      _;
    }
    // Methods -----------------------------------------------------------------

    function mintToken(address _owner)
      public
      payable
      returns(uint)
    {
      require(_owner != address(0), 'owner_addr');
      require(msg.value == mintFee_, 'msgValue_mintFee');

      uint tokenId = i_;

      i_ = i_.add(1);

      _registerToken(tokenId, _owner);

      return tokenId;
    }

    /// Get token owner address.
    /// @param _tokenId Token to get owner of.
    /// @return Owner of the token.
    function ownerOf(uint _tokenId)
      public
      view
      returns(address)
    {
      return ownership_[_tokenId];
    }

    function ownTokensCount(address _owner)
      public
      view
      returns(uint)
    {
      return ownTokens_[_owner].length;
    }

    function tokenByIndex(address _owner, uint _i)
      public
      view
      returns(uint)
    {
      return ownTokens_[_owner][_i];
    }

    /// Transfer token to another owner.
    /// @param _tokenId Token to transfer to.
    /// @param _newOwner New token owner.
    function transferTokenTo(uint _tokenId, address _newOwner)
      public
      tokenOwnerOnly(_tokenId)
    {
      require(_newOwner != address(0), 'newOwner_addr');

      _unregisterToken(_tokenId);
      _registerToken(_tokenId, _newOwner);
    }

    function burnToken(uint _tokenId)
      public
      tokenGameOnly(_tokenId)
    {
      _unregisterToken(_tokenId);

      emit TokenOwnership(_tokenId, address(0));
    }

    function _registerToken(uint _tokenId, address _owner)
      internal
    {
      ownIndexes_[_tokenId] = ownTokens_[_owner].length;
      ownTokens_[_owner].push(_tokenId);
      ownership_[_tokenId] = _owner;

      emit TokenOwnership(_tokenId, _owner);
    }

    function _unregisterToken(uint _tokenId)
      internal
    {
      address owner = ownership_[_tokenId];
      uint index = ownIndexes_[_tokenId];

      if (index != ownTokens_[owner].length - 1) {
        uint lastToken = ownTokens_[owner][ownTokens_[owner].length - 1];
        ownTokens_[owner][index] = lastToken;
        ownIndexes_[lastToken] = index;
      }
      else {
        ownTokens_[owner].length--;
      }
    }

    function registerGame(address _game)
      public
      payable
    {
      require(regStatus_[_game] == false, 'game_regStatus');
      require(msg.value == regFee_, 'msgValue_regFee');

      Game g = Game(_game);

      require(g.supportsInterface(bytes4(0x06fdde03)), 'game_interface');
      require(msg.sender == g.owner(), 'gameOwner_only');

      games_[_game] = true;
    }

    function activateGame(address _game, uint _tokenId)
      public
      tokenOwnerOnly(_tokenId)
    {
      require(games_[_game] == true, 'game_missing');

      if (playedGames_[_tokenId][_game] != true) {
        playedGames_[_tokenId][_game] = true;
        playedGamesList_[_tokenId].push(_game);
      }

      activeGames_[_tokenId][_game] = true;
    }

    function startPlay(uint _tokenId, uint _game)
      public
      tokenOwnerOnly(_tokenId)
    {
      require(tokenGame_[_tokenId] == address(0), 'token_inUse');
      require(games_[_game], 'game_registered');

      tokenGame_[_tokenId] = _game;
    }

    function stopPlay(uint _tokenId)
      public
      tokenGameOnly(_tokenId)
    {
      require(games_[msg.sender], 'game_registerd');
      tokenGame_[_tokenId] = address(0);
    }
}

contract DragonEngine is Engine {
  using SafeMath for uint;

  /// Engine name
  string public constant name = 'DragonEngine';
  /// Engine version
  uint public constant version = 1;

  uint public readyToken = 0;
  address public matchCounter = 0;

  mapping(uint => uint) internal health_;
  mapping(uint => uint) internal battleground_;
  mapping(uint => address) internal first_;
  mapping(uint => address) internal second_;
  mapping(uint => uint[]) internal history_;
  mapping(uint => mapping(uint => bytes32)) internal proofs_;
  mapping(uint => mapping(uint => bool)[]) internal proofStage_;
  mapping(uint => mapping(uint => bool)[]) internal disclosureStage_;
  mapping(uint => mapping(uint => uint)[]) internal attacks_;
  mapping(uint => mapping(uint => uint)[]) internal blocks_;
  mapping(uint => uint) internal steps_;

  event Win(uint winner, uint looser);

  modifier tokenOwnerOnly(uint _tokenId) {
    Platform platform = Platform(Game(game).platform());
    require(platform.ownerOf(_tokenId) == msg.sender, 'tokenOwnerOnly');
    _;
  }

  function startBattle(uint _tokenId)
    public
    payable
  {
    if (readyToken == 0) {
      matchCounter = matchCounter.add(1);
      readyToken = _tokenId;
      battleground_[_tokenId] = matchCounter;
      history_[_tokenId].push(matchCounter);
      health_[_tokenId] = Game(game).getParam('health');
      first_[matchCounter] = _tokenId;
    }
    else {
      readyToken = 0;
      battleground_[_tokenId] = matchCounter;
      history_[_tokenId].push(matchCounter);
      health_[_tokenId] = Game(game).getParam('health');
      second_[matchCounter] = _tokenId;
    }
  }

  function sendMoveProof(uint _tokenId, bytes32 proof)
    public
    tokenOwnerOnly(_tokenId)
  {
    uint bg = battleground_[_tokenId];
    uint step = steps_[bg];
    bool stage = stages_[bg][step];

    require(stage == false, 'proof_stage');

    proofs_[bg][msg.sender] = proof;

    address enemy;
    if (first_[bg] == msg.sender) {
      enemy = second_[bg];
    }
    else {
      enemy = first_[bg];
    }

    if (stages_[bg][step][enemy]) {
      stages_[bg][step] = true;
    }
    else if (stages_[bg][step][msg.sender]) {
      revert('duplicate step');
    }
    else {
      stages_[bg][step][msg.sender] = true;
    }
  }

  function sendMoveParams(uint _tokenId, uint attack, uint block, bytes32 _garbage)
    public
    tokenOwnerOnly(_tokenId)
  {
    uint bg = battleground_[_tokenId];
    uint step = steps_[bg];
    bool stage = stages_[bg][step];

    require(stage == true, 'proof_stage');

    bytes32 proof = proofs_[bg][msg.sender];

    address enemy;
    if (first_[bg] == msg.sender) {
      enemy = second_[bg];
    }
    else {
      enemy = first_[bg];
    }

    if (stages_[bg][step][enemy]) {
      stages_[bg][step] = false;
      // TODO Colse step
    }
    else if (stages_[bg][step][msg.sender]) {
      revert('duplicate step');
    }
    else {
      stages_[bg][step][msg.sender] = true;
    }

    bytes32 hash = keccak256(
      bytes(attack),
      bytes(block),
      _garbage
    );
  }

  function giveUp(uint _tokenId)
    public
    tokenOwnerOnly(_tokenId)
  {
    uint bg = battleground_[_tokenId];

    battleground_[_tokenId] = 0;

  }

  function getHealth(uint _tokenId)
    public
    pure
    returns(uint)
  {
    return health_[_tokenId];
  }

  function getBattleground(uint _tokenId)
    public
    view
    returns(uint)
  {
    return battleground_[_tokenId];
  }

  function getBattlegroundStep(uint _bg)
    public
    view
    returns(uint)
  {
    return steps_[_bg];
  }

  function getAttack(uint _tokenId, uint _step)
    public
    returns(uint)
  {
    uint bg = battleground_[_tokenId];
    if (bg == 0) {
      return 0;
    }

    if (steps_[bg] < _step) {
      return 0;
    }

    return attacks_[bg][_step][_tokenId];
  }

  function getBlock(uint _tokenId, uint _step)
    public
    returns(uint)
  {
    uint bg = battleground_[_tokenId];
    if (bg == 0) {
      return 0;
    }

    if (steps_[bg] < _step) {
      return 0;
    }

    return blocks_[bg][_step][_tokenId];
  }
}
