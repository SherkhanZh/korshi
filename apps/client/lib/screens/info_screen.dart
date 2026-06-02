import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class InfoSection {
  const InfoSection(this.heading, this.body);
  final String heading;
  final String body;
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.sections});

  final String title;
  final List<InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sections[i].heading,
                  style: AppTheme.cardTitle.copyWith(fontSize: 16, color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(sections[i].body, style: AppTheme.body.copyWith(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Predefined content ───
  static InfoScreen faq() => const InfoScreen(
        title: 'Вопросы / Помощь',
        sections: [
          InfoSection('Как подать заявку?',
              'Нажмите зелёную кнопку «+» внизу, выберите категорию, добавьте фото и описание, и отправьте. Председатель получит уведомление сразу.'),
          InfoSection('Как отслеживать статус?',
              'Откройте «Мои заявки» в профиле. Там виден статус каждой заявки и сообщения председателя.'),
          InfoSection('Как голосовать в опросах?',
              'Перейдите во вкладку «Опросы», выберите вариант и нажмите «Голосовать». Один голос на домохозяйство.'),
          InfoSection('Не приходят уведомления',
              'Проверьте, что уведомления включены в профиле, и что приложению разрешены push-уведомления в настройках телефона.'),
        ],
      );

  static InfoScreen privacy() => const InfoScreen(
        title: 'Политика конфиденциальности',
        sections: [
          InfoSection('Какие данные мы собираем',
              'Номер телефона, адрес в районе и содержимое ваших заявок. Эти данные нужны для работы сервиса и связи с председателем.'),
          InfoSection('Как мы используем данные',
              'Данные используются только для управления районом: обработки заявок, опросов и объявлений. Мы не продаём ваши данные третьим лицам.'),
          InfoSection('Кто видит ваши данные',
              'Ваши заявки видит председатель вашего района. Другие жители не видят ваши персональные данные.'),
          InfoSection('Хранение и удаление',
              'Вы можете запросить удаление аккаунта и данных, связавшись с председателем района.'),
        ],
      );

  static InfoScreen terms() => const InfoScreen(
        title: 'Условия использования',
        sections: [
          InfoSection('Назначение сервиса',
              'Korshi помогает жителям и председателю района совместно решать локальные вопросы. Доступ предоставляется председателем.'),
          InfoSection('Правила сообщества',
              'Будьте вежливы. Не отправляйте ложные заявки и спам. Уважайте других жителей и службы района.'),
          InfoSection('Ответственность',
              'Сервис предоставляется «как есть». Сроки решения заявок зависят от председателя и городских служб.'),
          InfoSection('Изменения условий',
              'Условия могут обновляться. Об изменениях вы узнаете в разделе объявлений.'),
        ],
      );
}
