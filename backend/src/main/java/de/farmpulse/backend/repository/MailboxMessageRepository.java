package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.MailboxMessage;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MailboxMessageRepository extends JpaRepository<MailboxMessage, Long> {

    List<MailboxMessage> findByFarmIdOrderByCreatedAtDesc(Long farmId);

    long countByFarmIdAndReadFalse(Long farmId);
}
