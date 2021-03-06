//
//  Created by yasuhiko2 on 04/03/2020.
//  Copyright © 2020 yasuhiko2. All rights reserved.
//

import UIKit

class SetViewController: UIViewController {

    private var game = Game()

    private let barInfo: BarInfo = {
        let stackView = BarInfo()
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    private let playingTableView: GameTableView = {
        let tableView = GameTableView()
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        playingTableView.delegate = self
        [barInfo, playingTableView].forEach({ view.addSubview($0)})

        setupLayout()
    }

    private func configure() {
        view.backgroundColor = .gameTableColor
        let tap = UITapGestureRecognizer(
                target: self, action: #selector(layingOutThreeCardsOnTable))
        barInfo.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateViewFromModel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            self.updateViewFromModel()
        })
    }

    @objc private func layingOutThreeCardsOnTable() {
        game.addCardsOnTable(countOfCards: 3)
        updateViewFromModel()
    }

    private func updateViewFromModel() {
        barInfo.layingOutCardsLabel.alpha = game.deck.isEmpty() ? 0 : 1
        let matchedCards = playingTableView.views.filter {
            game.lastMatchedCard.contains($0.card)
        }
        playingTableView.cards = game.cardOnTable
        playingTableView.views.forEach {
            $0.isSelected = game.cardsOnHands.contains($0.card)
        }
        let needLayingOutCards = playingTableView.views.filter {
            game.lastAddedCard.contains($0.card)
        }

        game.lastAddedCard.removeAll()
        game.lastMatchedCard.removeAll()

        layingOutCardAnimation(needLayingOutCards)
        cardsAfterMatchedAnimation(matchedCards: matchedCards)
    }

    // MARK: - Dynamic Animator
    private lazy var animator = UIDynamicAnimator(referenceView: playingTableView)
    private lazy var cardBehavior = CardBehavior(in: animator)

    private func layingOutCardAnimation(_ cardViews: [CardView]) {
        for index in cardViews.indices {
            let cardView = cardViews[index]
            let cardMoveTo = cardView.frame
            cardView.frame = deckOriginFrame
            cardView.isFaceUp = false

            let flipCardOnDeckAnimation: () -> () = {
                UIView.transition(
                        with: cardView,
                        duration: 0.5,
                        options: [.transitionFlipFromLeft],
                        animations: { cardView.isFaceUp = true }
                )
            }
            UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.6,
                    delay: TimeInterval(index) * 0.3,
                    animations: { cardView.frame = cardMoveTo },
                    completion: { _ in flipCardOnDeckAnimation() }
            )
        }
    }

    private func cardsAfterMatchedAnimation(matchedCards: [CardView]) {
        for matchCard in matchedCards {
            matchCard.isSelected = false
            let horizontalRotationCardAnimation = {
                matchCard.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi / 2)
            }

            let flipOnStackOfCardsAnimation: (UIViewAnimatingPosition) -> () = { _ in
                self.barInfo.numberOfCollectedSetsLabel.alpha = 0
                UIView.transition(
                        with: matchCard,
                        duration: 0.8,
                        options: [.transitionFlipFromLeft],
                        animations: { matchCard.isFaceUp = false },
                        completion: { _ in
                            self.barInfo.numberOfCollectedSetsLabel.alpha = 1
                            self.barInfo.numberOfCollectedSetsLabel.text = "\(self.game.matchedCount) Sets"
                            matchCard.alpha = 0
                        }
                )
            }

            let moveCardsToStackOfCardsAnimation: (Bool) -> () = { _ in
                UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.5,
                        delay: 0.1,
                        options: [.curveEaseIn],
                        animations: { matchCard.frame = self.setCountViewFrame },
                        completion: flipOnStackOfCardsAnimation)
            }

            playingTableView.addSubview(matchCard)
            cardBehavior.addItem(matchCard)

            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
                self.cardBehavior.removeItem(matchCard)
                UIView.transition(
                        with: matchCard,
                        duration: 0.2,
                        animations: { horizontalRotationCardAnimation() },
                        completion: moveCardsToStackOfCardsAnimation)
            })
        }
    }
}

// MARK: - SetTableViewDelegate
extension SetViewController: SetTableViewDelegate {
    func clickOnCard(card: Card) {
        game.cardsOnHands.contains(card) ? game.discard(card: card) :
                game.takeCardFromTable(card: card)
        updateViewFromModel()
    }
}

extension SetViewController {
    private var setCountViewCenter: CGPoint {
        barInfo.convert(barInfo.numberOfCollectedSetsLabel.frame.origin, to: playingTableView)
    }

    private var setCountViewFrame: CGRect {
        CGRect(origin: setCountViewCenter, size: barInfo.layingOutCardsLabel.frame.size)
    }

    private var deckOriginCenter: CGPoint {
        barInfo.convert(barInfo.layingOutCardsLabel.frame.origin, to: playingTableView)
    }

    private var deckOriginFrame: CGRect {
        CGRect(origin: deckOriginCenter, size: barInfo.layingOutCardsLabel.frame.size)
    }
}

// MARK: - Autolayout
extension SetViewController {
    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide

        let constraints = [
            barInfo.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            barInfo.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            barInfo.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -4),
            barInfo.topAnchor.constraint(equalTo: playingTableView.bottomAnchor, constant: 4),
            barInfo.heightAnchor.constraint(equalToConstant: 80),

            playingTableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            playingTableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            playingTableView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 4)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}

