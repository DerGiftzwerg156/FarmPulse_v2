package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.SeasonGoal;
import de.farmpulse.backend.domain.SeasonGoalStatus;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SeasonGoalRepository extends JpaRepository<SeasonGoal, Long> {

    Optional<SeasonGoal> findFirstByFarmIdAndStatusOrderByCreatedAtDesc(Long farmId, SeasonGoalStatus status);
}
