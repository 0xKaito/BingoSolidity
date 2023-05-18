// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


///@notice contract to play bingo game
contract Bingo {
    
    event newGameStarted(uint256 _gameId);
    event randomGenereated(uint256 _number);
    event playerEnter(address _player);
    event win(address _player);

    address owner;
    IERC20 token;
    uint256 public fees;
    uint256 public joinDurationTime;
    uint256 public turnDurationTime;
    struct Board {
        uint256[5] b;
        uint256[5] i;
        uint256[5] n;
        uint256[5] g;
        uint256[5] o;
    }
    mapping(bytes32 => bool) Bool;
    mapping(uint256 => bool) startGame;
    mapping(uint256 => uint256) playersInGame;
    mapping(uint256 => uint256) newRandomNumber;
    mapping(uint256 => address) winner;
    mapping(uint256 => mapping(address => Board)) userCard;
    mapping(uint256 => mapping(address => bool)) register;

    ///@notice initialize fees, join duration time, turn duration time and Bigno token
    ///@param _fees fees to play game
    ///@param _joinDurationTime to join game in this time
    ///@param _bingoToken ERC20 token
    constructor(
        address _bingoToken,
        uint256 _fees,
        uint256 _joinDurationTime,
        uint256 _turnDurationTime
    ) {
        owner = msg.sender;
        fees = _fees;
        joinDurationTime = block.timestamp + _joinDurationTime;
        turnDurationTime = _turnDurationTime;
        token = IERC20(_bingoToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    ///@notice update fees of playing game, only owner can update fees
    ///@param _fees fees of playing game
    function updateFees(uint256 _fees) external onlyOwner {
        fees = _fees;
    }

    ///@notice update join duration time, only owner can update join duration time
    ///@param _joinDurationTime join time 
    function updateJoinDurationTime(uint256 _joinDurationTime) external onlyOwner {
        joinDurationTime = _joinDurationTime;
    }

    ///@notice only owner can update turn duration time
    ///@param _turnDurationTime turn time
    function updateTurnDurationTime(uint256 _turnDurationTime) external onlyOwner {
        turnDurationTime = _turnDurationTime;
    }

    ///@notice to start game
    ///@param _gameId id of game
    function startNewGame(uint256 _gameId) external onlyOwner {
        require(block.timestamp >= joinDurationTime, "join duration has not ended");
        startGame[_gameId] = true;
        emit newGameStarted(_gameId);
    }

    ///@notice to create bingo ticket for player
    ///@param _gameId game where player wants to play
    function createBoard(uint256 _gameId) external {
        require(!startGame[_gameId], "game has started");
        require(token.balanceOf(msg.sender) >= fees, "not enough balance");
        token.transferFrom(msg.sender, address(this), fees);
        userCard[_gameId][msg.sender] = generateBoard();
        register[_gameId][msg.sender] = true;
        playersInGame[_gameId]++;
        emit playerEnter(msg.sender);
    }

    ///@notice owner generate random number to cut number in player board
    ///@param _gameId id of game
    function generateRandom(uint256 _gameId) external onlyOwner {
        newRandomNumber[_gameId] = uint256(blockhash(block.number - 1)) % 100;
        emit randomGenereated(newRandomNumber[_gameId]);
    }

    ///@notice player marks its board if newRandomNumber matches in borad
    ///@param _gameId id of game
    function cutNumberInBoard(uint256 _gameId) external {
        require(startGame[_gameId], "game not started");
        require(register[_gameId][msg.sender], "not registered");
        Board memory playerBoard = userCard[_gameId][msg.sender];
        for (uint256 i; i < 5; i++) {
            for (uint256 j; j < 5; j++) {
                bytes32 k = keccak256(abi.encode(msg.sender, _gameId, i, j));
                Bool[k];
                if (i == 0 && newRandomNumber[_gameId] == playerBoard.b[j]) {
                    Bool[k] = true;
                } else if (i == 1 && newRandomNumber[_gameId] == playerBoard.i[j]) {
                    Bool[k] = true;
                } else if (i == 2 && newRandomNumber[_gameId] == playerBoard.n[j]) {
                    Bool[k] = true;
                } else if (i == 3 && newRandomNumber[_gameId] == playerBoard.g[j]) {
                    Bool[k] = true;
                } else if (i == 4 && newRandomNumber[_gameId] == playerBoard.o[j]) {
                    Bool[k] = true;
                }
            }
        }
    }

    ///@notice winner can claim its reward
    ///@param _gameId id of game
    function claim(uint256 _gameId) external {
        require(winner[_gameId] == msg.sender, "can not claim");
        token.transfer(msg.sender, fees*playersInGame[_gameId]);
    }

    ///@notice to check player has won or not
    ///@param _gameId id of game
    function validate(uint256 _gameId)
        external
    {
        require(startGame[_gameId], "game ended or not started yet");
        require(register[_gameId][msg.sender], "not registered");
        for (uint256 i; i < 5; i++) {
            uint256[4] memory matches;
            for (uint256 j; j<5; j++) {
                bytes32 k = keccak256(abi.encode(msg.sender, _gameId, i, j));
                bytes32 k1 = keccak256(abi.encode(msg.sender, _gameId, j, i));
                if(Bool[k] == true){
                    if(i==j){
                        matches[2]++;
                    }
                    if((i==0 && j==4) || (i==1 && j==3) || (i==2 && j==2) || (i==3 && j==1) || (i==4 && j==0)){
                        matches[3]++;
                    }
                    matches[0]++;
                }
                if(Bool[k1] == true) {
                    matches[1]++;
                }
            }
            if((matches[0] == 5 || matches[1] == 5) || (matches[2] == 5 || matches[3] == 5)) {
                winner[_gameId] = msg.sender;
                startGame[_gameId] = false;
                newRandomNumber[_gameId] = 0;
                emit win(msg.sender);
            }
        }
    }

    ///@notice to game has started 
    function gameStart(uint256 _gameId) external view returns(bool){
        return startGame[_gameId];
    }

    ///@notice shows number of player in game
    function numberOfPlayer(uint256 _gameId) external view returns(uint256) {
        return playersInGame[_gameId];
    }

    ///@notice shows new random number generated
    function randomNumber(uint256 _gameId) external view returns(uint256) {
        return newRandomNumber[_gameId];
    }

    function generateBoard() internal view returns (Board memory) {
        Board memory board;
        for (uint256 i; i < 5; i++) {
            uint256[5] memory col;
            for (uint256 j; j < 5; j++) {
                col[j] = uint256(blockhash(block.number - 1)) % 100;
            }
            if (i == 0) {
                board.b = col;
            } else if (i == 1) {
                board.i = col;
            } else if (i == 2) {
                board.n = col;
            } else if (i == 3) {
                board.g = col;
            } else if (i == 4) {
                board.o = col;
            }
        }
        return board;
    }
}
