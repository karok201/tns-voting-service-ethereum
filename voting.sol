// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting {
    enum VotingType { Quorum, TwoUserDecision }
    enum VotingStatus { Active, Ended, Rejected }

    struct VoteSession {
        string description;
        uint256 endTime;
        VotingType voteType;
        address[] voters;
        mapping(address => bool) hasVoted;
        uint256 yesVotes;
        uint256 noVotes;
        VotingStatus status;
    }

    struct VoteSessionInfo {
        uint256 voteId;
        string description;
        uint256 endTime;
        VotingType voteType;
        address[] voters;
        uint256 yesVotes;
        uint256 noVotes;
        VotingStatus status;
    }

    uint256 public voteCount;
    mapping(uint256 => VoteSession) public votes;
    
    event VoteCreated(uint256 voteId, string description, uint256 endTime, VotingType voteType);
    event Voted(uint256 voteId, address voter, bool decision);
    event VotingEnded(uint256 voteId, VotingStatus status);

    modifier onlyBeforeEnd(uint256 _voteId) {
        require(block.timestamp < votes[_voteId].endTime, "Voting has ended");
        _;
    }

    function createVote(string memory _description, uint256 _duration, VotingType _voteType, address[] memory _voters) public {
        require(_voters.length >= 2, "At least two voters required");
        voteCount++;
        
        // Создание голосования и запись данных отдельно
        VoteSession storage session = votes[voteCount];
        session.description = _description;
        session.endTime = block.timestamp + _duration;
        session.voteType = _voteType;
        session.voters = _voters;
        session.status = VotingStatus.Active;

        emit VoteCreated(voteCount, _description, session.endTime, _voteType);
    }

    function vote(uint256 _voteId, bool _decision) public onlyBeforeEnd(_voteId) {
        VoteSession storage session = votes[_voteId];

        require(!session.hasVoted[msg.sender], "You have already voted");
        require(session.status == VotingStatus.Active, "Voting is not active");

        session.hasVoted[msg.sender] = true;
        if (_decision) {
            session.yesVotes++;
        } else {
            session.noVotes++;
        }

        emit Voted(_voteId, msg.sender, _decision);
    }

    function endVoting(uint256 _voteId) public {
        VoteSession storage session = votes[_voteId];
        require(block.timestamp >= session.endTime, "Voting period not yet over");
        require(session.status == VotingStatus.Active, "Voting already ended");

        uint256 totalVotes = session.yesVotes + session.noVotes;

        if (session.voteType == VotingType.Quorum) {
            if (totalVotes >= session.voters.length / 2) {
                session.status = VotingStatus.Ended;
            } else {
                session.status = VotingStatus.Rejected;
            }
        } else if (session.voteType == VotingType.TwoUserDecision) {
            if (session.yesVotes >= 2) {
                session.status = VotingStatus.Ended;
            } else {
                session.status = VotingStatus.Rejected;
            }
        }

        emit VotingEnded(_voteId, session.status);
    }

    // Новая функция для получения всех голосований
    function getAllVotes() public view returns (VoteSessionInfo[] memory) {
        VoteSessionInfo[] memory allVotes = new VoteSessionInfo[](voteCount);
        
        for (uint256 i = 1; i <= voteCount; i++) {
            VoteSession storage session = votes[i];
            allVotes[i - 1] = VoteSessionInfo(
                i,                    // voteId
                session.description,  // описание
                session.endTime,      // время окончания
                session.voteType,     // тип голосования
                session.voters,       // список голосующих
                session.yesVotes,     // голоса "за"
                session.noVotes,      // голоса "против"
                session.status        // статус
            );
        }
        
        return allVotes;
    }
}

